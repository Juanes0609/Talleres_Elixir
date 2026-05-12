defmodule Inmobiliaria.PropertyManager do
  @moduledoc """
  GenServer que gestiona el ciclo de vida completo de las propiedades.

  Responsabilidades:
    - Publicar propiedades (generar id, iniciar proceso GenServer via DynamicSupervisor).
    - Listar y filtrar propiedades con diferentes criterios.
    - Coordinar compras y arriendos delegando al proceso Property correspondiente.
    - Actualizar puntajes de usuarios tras operaciones exitosas.
    - Registrar operaciones en results.log.
    - Persistir propiedades en properties.dat.
    - Al iniciar la app, cargar propiedades existentes y levantar sus procesos.

  Estado interno:
    %{
      properties: %{"prop001" => %Property{}, ...},  # mapa id -> struct
      next_id: 1                                      # contador para generar ids
    }
  """

  use GenServer
  require Logger

  alias Inmobiliaria.Property

  @properties_file Path.expand("data/properties.dat", File.cwd!())
  @results_file    Path.expand("data/results.log",    File.cwd!())

  # ---------------------------------------------------------------------------
  # API PÚBLICA
  # ---------------------------------------------------------------------------

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @doc """
  Publica una nueva propiedad. `attrs` es un mapa string-keyed:
    %{"tipo" => "casa", "modalidad" => "venta", "ubicacion" => "Armenia",
      "precio" => "300000000", "habitaciones" => "4", "area" => "180"}
  Retorna {:ok, %Property{}} | {:error, motivo}
  """
  def publish(username, attrs) do
    GenServer.call(__MODULE__, {:publish, username, attrs})
  end

  @doc """
  Lista propiedades filtrando por los criterios presentes en `filters`.
  Claves soportadas (todas opcionales, string-keyed):
    "tipo", "modalidad", "ubicacion", "precio_min", "precio_max", "estado"
  Sin filtros retorna solo las disponibles.
  """
  def list(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  @doc "Retorna el struct de una propiedad por su id"
  def get_property(prop_id) do
    GenServer.call(__MODULE__, {:get_property, prop_id})
  end

  @doc """
  Compra una propiedad disponible. Si exitoso:
    - Cambia estado a "vendida" en el proceso Property y en properties.dat
    - Suma puntos al cliente y al vendedor
    - Registra en results.log
  Retorna {:ok, %Property{}} | {:error, motivo}
  """
  def buy(prop_id, cliente) do
    GenServer.call(__MODULE__, {:buy, prop_id, cliente})
  end

  @doc """
  Arrienda una propiedad disponible. Si exitoso:
    - Cambia estado a "arrendada" en el proceso Property y en properties.dat
    - Suma puntos al cliente y al arrendador
    - Registra en results.log
  Retorna {:ok, %Property{}} | {:error, motivo}
  """
  def rent(prop_id, cliente) do
    GenServer.call(__MODULE__, {:rent, prop_id, cliente})
  end

  @doc "Retorna la lista de registros del historial (results.log)"
  def get_results() do
    GenServer.call(__MODULE__, :get_results)
  end

  # ---------------------------------------------------------------------------
  # INIT
  # ---------------------------------------------------------------------------

  @impl true
  def init(:ok) do
    ensure_storage!()
    properties = load_properties()

    # Levantar proceso GenServer por cada propiedad cargada
    Enum.each(properties, fn {_id, prop} ->
      case DynamicSupervisor.start_child(
             Inmobiliaria.PropertySupervisor,
             {Property, prop}
           ) do
        {:ok, _pid} ->
          Logger.info("Proceso iniciado para propiedad existente: #{prop.id}")
        {:error, reason} ->
          Logger.error("No se pudo iniciar proceso para #{prop.id}: #{inspect(reason)}")
      end
    end)

    next_id = map_size(properties) + 1
    {:ok, %{properties: properties, next_id: next_id}}
  end

  # ---------------------------------------------------------------------------
  # CALLBACKS
  # ---------------------------------------------------------------------------

  @impl true
  def handle_call({:publish, username, attrs}, _from, state) do
    prop_id = generate_id(state.next_id)

    with {:ok, precio}       <- parse_integer(attrs["precio"] || attrs[:precio], "precio"),
         {:ok, habitaciones} <- parse_integer(attrs["habitaciones"] || attrs[:habitaciones], "habitaciones"),
         {:ok, area}         <- parse_float(attrs["area"] || attrs[:area], "area") do

      nueva_prop = %Property{
        id:           prop_id,
        tipo:         attrs["tipo"] || attrs[:tipo] || "casa",
        modalidad:    attrs["modalidad"] || attrs[:modalidad] || "venta",
        ubicacion:    attrs["ubicacion"] || attrs[:ubicacion],
        precio:       precio,
        habitaciones: habitaciones,
        area:         area,
        propietario:  username,
        estado:       "disponible"
      }

      # Iniciar proceso GenServer para la nueva propiedad
      case DynamicSupervisor.start_child(
             Inmobiliaria.PropertySupervisor,
             {Property, nueva_prop}
           ) do
        {:ok, _pid} ->
          nuevo_state = %{
            state |
            properties: Map.put(state.properties, prop_id, nueva_prop),
            next_id: state.next_id + 1
          }
          flush(nuevo_state.properties)
          Logger.info("Propiedad publicada: #{prop_id} por #{username}")
          {:reply, {:ok, nueva_prop}, nuevo_state}

        {:error, reason} ->
          Logger.error("No se pudo iniciar proceso para #{prop_id}: #{inspect(reason)}")
          {:reply, {:error, "Error al iniciar proceso de la propiedad"}, state}
      end
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  @impl true
  def handle_call({:list, filters}, _from, state) do
    # Obtener estado en tiempo real desde cada proceso GenServer
    lista =
      state.properties
      |> Map.values()
      |> Enum.map(fn prop ->
        if Property.alive?(prop.id) do
          Property.get_info(prop.id)
        else
          prop
        end
      end)
      |> apply_filters(filters)

    {:reply, lista, state}
  end

  @impl true
  def handle_call({:get_property, prop_id}, _from, state) do
    case Map.fetch(state.properties, prop_id) do
      {:ok, prop} ->
        # Estado en tiempo real desde el proceso
        info = if Property.alive?(prop_id), do: Property.get_info(prop_id), else: prop
        {:reply, {:ok, info}, state}
      :error ->
        {:reply, {:error, "Propiedad #{prop_id} no encontrada"}, state}
    end
  end

  @impl true
  def handle_call({:buy, prop_id, cliente}, _from, state) do
    with {:ok, prop}         <- Map.fetch(state.properties, prop_id) |> normalize_fetch(prop_id),
         {:alive}            <- check_alive(prop_id),
         {:ok, prop_nueva}   <- Property.buy(prop_id, cliente) do

      # Actualizar estado en el mapa local y persistir
      nuevo_state = put_in(state, [:properties, prop_id], prop_nueva)
      flush(nuevo_state.properties)

      # Asignar puntos
      Inmobiliaria.UserManager.add_score(cliente, Inmobiliaria.UserManager.puntos_para(:cliente))
      Inmobiliaria.UserManager.add_score(prop.propietario, Inmobiliaria.UserManager.puntos_para(:vendedor))

      # Registrar en results.log
      log_result(%{
        cliente:      cliente,
        responsable:  prop.propietario,
        prop_id:      prop_id,
        operacion:    "compra",
        ubicacion:    prop.ubicacion,
        precio:       prop.precio,
        status:       "Completada"
      })

      {:reply, {:ok, prop_nueva}, nuevo_state}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  @impl true
  def handle_call({:rent, prop_id, cliente}, _from, state) do
    with {:ok, prop}         <- Map.fetch(state.properties, prop_id) |> normalize_fetch(prop_id),
         {:alive}            <- check_alive(prop_id),
         {:ok, prop_nueva}   <- Property.rent(prop_id, cliente) do

      nuevo_state = put_in(state, [:properties, prop_id], prop_nueva)
      flush(nuevo_state.properties)

      Inmobiliaria.UserManager.add_score(cliente, Inmobiliaria.UserManager.puntos_para(:cliente))
      Inmobiliaria.UserManager.add_score(prop.propietario, Inmobiliaria.UserManager.puntos_para(:arrendador))

      log_result(%{
        cliente:     cliente,
        responsable: prop.propietario,
        prop_id:     prop_id,
        operacion:   "arriendo",
        ubicacion:   prop.ubicacion,
        precio:      prop.precio,
        status:      "Completada"
      })

      {:reply, {:ok, prop_nueva}, nuevo_state}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  @impl true
  def handle_call(:get_results, _from, state) do
    {:reply, load_results(), state}
  end

  @impl true
  def handle_call(msg, from, state) do
    Logger.warning("PropertyManager: mensaje inesperado #{inspect(msg)} de #{inspect(from)}")
    {:reply, {:error, :unknown_command}, state}
  end

  # ---------------------------------------------------------------------------
  # PERSISTENCIA (privado)
  # ---------------------------------------------------------------------------

  defp ensure_storage! do
    File.mkdir_p!("data")
    unless File.exists?(@properties_file), do: File.write!(@properties_file, "")
    unless File.exists?(@results_file),    do: File.write!(@results_file, "")
    :ok
  end

  defp load_properties() do
    @properties_file
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&Property.from_line/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new(&{&1.id, &1})
  end

  defp flush(properties) do
    body =
      properties
      |> Map.values()
      |> Enum.map(&Property.to_line/1)
      |> Enum.join("\n")

    File.write!(@properties_file, body <> "\n")
  end

  defp log_result(r) do
    fecha = Date.to_string(Date.utc_today())
    linea = "#{fecha};cliente=#{r.cliente};responsable=#{r.responsable};" <>
            "propiedad=#{r.prop_id};operacion=#{r.operacion};" <>
            "ubicacion=#{r.ubicacion};precio=#{r.precio};status=#{r.status}\n"
    File.write!(@results_file, linea, [:append])
  end

  defp load_results() do
    @results_file
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_result_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_result_line(line) do
    # "fecha;cliente=ana;responsable=carlos;propiedad=prop001;..."
    parts = String.split(line, ";")
    if length(parts) == 8 do
      [fecha | kv_parts] = parts
      kvs = Map.new(kv_parts, fn part ->
        [k, v] = String.split(part, "=", parts: 2)
        {k, v}
      end)
      Map.put(kvs, "fecha", fecha)
    else
      nil
    end
  end

  # ---------------------------------------------------------------------------
  # HELPERS PRIVADOS
  # ---------------------------------------------------------------------------

  defp generate_id(n) do
    "prop" <> String.pad_leading(Integer.to_string(n), 3, "0")
    # Genera: prop001, prop002, prop003, ...
  end

  defp apply_filters(lista, filters) when map_size(filters) == 0 do
    Enum.filter(lista, &(&1.estado == "disponible"))
  end

  defp apply_filters(lista, filters) do
    lista
    |> maybe_filter(filters, "tipo",      &(&1.tipo == &2))
    |> maybe_filter(filters, "modalidad", &(&1.modalidad == &2))
    |> maybe_filter(filters, "ubicacion", &(String.downcase(&1.ubicacion) == String.downcase(&2)))
    |> maybe_filter(filters, "estado",    &(&1.estado == &2))
    |> maybe_filter_int(filters, "precio_min", &(&1.precio >= &2))
    |> maybe_filter_int(filters, "precio_max", &(&1.precio <= &2))
  end

  defp maybe_filter(lista, filters, key, fun) do
    case Map.fetch(filters, key) do
      {:ok, val} -> Enum.filter(lista, &fun.(&1, val))
      :error     -> lista
    end
  end

  defp maybe_filter_int(lista, filters, key, fun) do
    case Map.fetch(filters, key) do
      {:ok, val_str} ->
        case Integer.parse(val_str) do
          {n, _} -> Enum.filter(lista, &fun.(&1, n))
          :error -> lista
        end
      :error -> lista
    end
  end

  defp parse_integer(nil, campo), do: {:error, "Falta el campo: #{campo}"}
  defp parse_integer(val, campo) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> {:ok, n}
      :error -> {:error, "El campo #{campo} debe ser un número entero"}
    end
  end
  defp parse_integer(val, _) when is_integer(val), do: {:ok, val}

  defp parse_float(nil, campo), do: {:error, "Falta el campo: #{campo}"}
  defp parse_float(val, campo) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> {:ok, f}
      :error ->
        case Integer.parse(val) do
          {n, _} -> {:ok, n * 1.0}
          :error -> {:error, "El campo #{campo} debe ser un número"}
        end
    end
  end
  defp parse_float(val, _) when is_float(val), do: {:ok, val}
  defp parse_float(val, _) when is_integer(val), do: {:ok, val * 1.0}

  defp normalize_fetch({:ok, val}, _), do: {:ok, val}
  defp normalize_fetch(:error, id),    do: {:error, "Propiedad #{id} no encontrada"}

  defp check_alive(prop_id) do
    if Property.alive?(prop_id), do: {:alive}, else: {:error, "El proceso de la propiedad no está activo"}
  end
end
