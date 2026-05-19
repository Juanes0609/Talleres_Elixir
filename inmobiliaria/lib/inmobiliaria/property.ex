defmodule Inmobiliaria.Property do
  @moduledoc """
  GenServer que representa una propiedad individual en el sistema.

  Cada propiedad es un proceso independiente supervisado por
  Inmobiliaria.PropertySupervisor (DynamicSupervisor).

  El proceso se registra en el Registry con su prop_id, lo que permite
  encontrarlo desde cualquier parte del sistema usando via_tuple/1.

  La serialización del GenServer garantiza que si dos clientes intentan
  comprar/arrendar la misma propiedad simultáneamente, solo una operación
  se completa — la segunda llega cuando el estado ya cambió a "vendida".
  """

  use GenServer
  require Logger

  # ---------------------------------------------------------------------------
  # STRUCT
  # ---------------------------------------------------------------------------

  @enforce_keys [:id, :tipo, :modalidad, :ubicacion, :precio, :habitaciones, :area, :propietario]
  defstruct [
    # String único, ej: "prop001"
    :id,
    # "casa" | "apartamento" | "oficina" | "lote"
    :tipo,
    # "venta" | "arriendo"
    :modalidad,
    # String, debe existir en locations.dat
    :ubicacion,
    # Integer (en pesos colombianos)
    :precio,
    # Integer
    :habitaciones,
    # Float (metros cuadrados)
    :area,
    # String (username del vendedor/arrendador)
    :propietario,
    # "disponible" | "reservada" | "vendida" | "arrendada"
    estado: "disponible"
  ]

  # ---------------------------------------------------------------------------
  # API PÚBLICA
  # ---------------------------------------------------------------------------

  def start_link(%__MODULE__{} = property) do
    GenServer.start_link(__MODULE__, property, name: via_tuple(property.id))
  end

  @doc "Retorna todos los datos actuales de la propiedad en tiempo real"
  def get_info(prop_id) do
    GenServer.call(via_tuple(prop_id), :get_info)
  end

  @doc """
  Intenta comprar la propiedad.
  Retorna {:ok, property_actualizada} | {:error, motivo}
  La serialización del GenServer evita condiciones de carrera.
  """
  def buy(prop_id, cliente) do
    GenServer.call(via_tuple(prop_id), {:buy, cliente})
  end

  @doc """
  Intenta arrendar la propiedad.
  Retorna {:ok, property_actualizada} | {:error, motivo}
  """
  def rent(prop_id, cliente) do
    GenServer.call(via_tuple(prop_id), {:rent, cliente})
  end

  @doc "Intenta reservar temporalmente la propiedad."
  def reserve(prop_id, cliente) do
    GenServer.call(via_tuple(prop_id), {:reserve, cliente})
  end

  @doc "Cancela una operación sobre la propiedad"
  def cancel(prop_id, cliente) do
    GenServer.call(via_tuple(prop_id), {:cancel, cliente})
  end

  @doc "Actualiza el estado manualmente (uso interno del PropertyManager)"
  def update_estado(prop_id, nuevo_estado) do
    GenServer.call(via_tuple(prop_id), {:update_estado, nuevo_estado})
  end

  @doc "Verifica si el proceso de la propiedad está corriendo"
  def alive?(prop_id) do
    case Registry.lookup(Inmobiliaria.PropertyRegistry, prop_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  # ---------------------------------------------------------------------------
  # CALLBACKS DEL GENSERVER
  # ---------------------------------------------------------------------------

  @impl true
  def init(%__MODULE__{} = property) do
    Logger.info(
      "Proceso iniciado para propiedad #{property.id} (#{property.tipo} en #{property.ubicacion})"
    )

    {:ok, property}
  end

  @impl true
  def handle_call(:get_info, _from, property) do
    {:reply, property, property}
  end

  @impl true
  def handle_call({:buy, cliente}, _from, property) do
    cond do
      property.estado != "disponible" ->
        {:reply, {:error, "La propiedad no esta disponible (estado: #{property.estado})"},
         property}

      property.modalidad != "venta" ->
        {:reply, {:error, "Esta propiedad es de arriendo, no de venta"}, property}

      true ->
        nueva = %{property | estado: "vendida"}
        Logger.info("Propiedad #{property.id} comprada por #{cliente}")
        {:reply, {:ok, nueva}, nueva}
    end
  end

  @impl true
  def handle_call({:rent, cliente}, _from, property) do
    cond do
      property.estado != "disponible" ->
        {:reply, {:error, "La propiedad no esta disponible (estado: #{property.estado})"},
         property}

      property.modalidad != "arriendo" ->
        {:reply, {:error, "Esta propiedad es de venta, no de arriendo"}, property}

      true ->
        nueva = %{property | estado: "arrendada"}
        Logger.info("Propiedad #{property.id} arrendada por #{cliente}")
        {:reply, {:ok, nueva}, nueva}
    end
  end

  @impl true
  def handle_call({:reserve, _cliente}, _from, property) do
    cond do
      property.estado != "disponible" ->
        {:reply, {:error, "La propiedad no está disponible (estado: #{property.estado})"}, property}

        true ->
          nueva_prop = %{property | estado: "reservada"}
        {:reply, {:ok, nueva_prop}, nueva_prop}
    end
  end

  @impl true
  def handle_call({:cancel, _cliente}, _from, property) do
    cond do
      property.estado not in ["reservada", "vendida", "arrendada"]->
        {:reply, {:error, "La propiedad no tiene operaciones para cancelar"}, property}

        true ->
          nueva_prop = %{property | estado: "disponible"}
        {:reply, {:ok, nueva_prop}, nueva_prop}
    end
  end

  @impl true
  def handle_call({:update_estado, nuevo_estado}, _from, property) do
    nueva = %{property | estado: nuevo_estado}
    {:reply, {:ok, nueva}, nueva}
  end

  @impl true
  def handle_call(msg, from, property) do
    Logger.warning(
      "Property #{property.id}: mensaje inesperado #{inspect(msg)} de #{inspect(from)}"
    )

    {:reply, {:error, :unknown}, property}
  end

  # ---------------------------------------------------------------------------
  # HELPERS PÚBLICOS (usados por PropertyManager)
  # ---------------------------------------------------------------------------

  @doc """
  Construye el nombre via Registry para encontrar el proceso por prop_id.
  Uso: GenServer.call(via_tuple("prop001"), :get_info)
  """
  def via_tuple(prop_id) do
    {:via, Registry, {Inmobiliaria.PropertyRegistry, prop_id}}
  end

  @doc """
  Convierte el struct a una línea de texto para properties.dat.
  Formato: id;tipo;modalidad;ubicacion;precio;habitaciones;area;estado;propietario
  """
  def to_line(%__MODULE__{} = p) do
    [
      p.id,
      p.tipo,
      p.modalidad,
      p.ubicacion,
      Integer.to_string(p.precio),
      Integer.to_string(p.habitaciones),
      Float.to_string(p.area / 1),
      p.estado,
      p.propietario
    ]
    |> Enum.join(";")
  end

  @doc """
  Parsea una línea de properties.dat y retorna un struct Property.
  Retorna %Property{} | nil si la línea es inválida.
  """
  def from_line(line) do
    case String.split(String.trim(line), ";") do
      [id, tipo, modalidad, ubicacion, precio_s, hab_s, area_s, estado, propietario] ->
        with {precio, _} <- Integer.parse(precio_s),
             {habitaciones, _} <- Integer.parse(hab_s),
             {area, _} <- Float.parse(area_s) do
          %__MODULE__{
            id: id,
            tipo: tipo,
            modalidad: modalidad,
            ubicacion: ubicacion,
            precio: precio,
            habitaciones: habitaciones,
            area: area,
            estado: estado,
            propietario: propietario
          }
        else
          _ ->
            Logger.warning("Property: linea con numeros invalidos -> #{line}")
            nil
        end

      _ ->
        Logger.warning("Property: linea invalida en properties.dat -> #{line}")
        nil
    end
  end
end
