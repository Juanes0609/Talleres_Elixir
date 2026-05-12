defmodule Inmobiliaria.MessageManager do
  @moduledoc """
  GenServer que gestiona la mensajería entre clientes y responsables de propiedades.

  Responsabilidades:
    - Permitir a cualquier usuario autenticado enviar mensajes al propietario
      de una propiedad específica.
    - Permitir a vendedores/arrendadores leer mensajes de sus propiedades.
    - Persistir todos los mensajes en messages.log usando append (no reescribe).
    - Cargar el historial completo al iniciar.

  Estado interno:
    lista de %MessageManager{} ordenada por fecha/hora de llegada

  Formato de messages.log (una línea por mensaje):
    fecha;hora;from=<username>;prop_id=<id>;mensaje=<texto>
  Ejemplo:
    2026-03-17;20:30:00;from=ana;prop_id=prop001;mensaje=Hola, ¿sigue disponible?
  """

  use GenServer
  require Logger

  @path Path.expand("data/messages.log", File.cwd!())

  # ---------------------------------------------------------------------------
  # STRUCT
  # ---------------------------------------------------------------------------

  defstruct [:fecha, :hora, :from, :prop_id, :mensaje]

  # ---------------------------------------------------------------------------
  # API PÚBLICA
  # ---------------------------------------------------------------------------

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @doc """
  Envía un mensaje de `from` sobre la propiedad `prop_id`.
  Retorna :ok | {:error, motivo}
  """
  def send_message(from, prop_id, mensaje) do
    GenServer.call(__MODULE__, {:send_message, from, prop_id, mensaje})
  end

  @doc "Retorna todos los mensajes de una propiedad específica"
  def get_messages(prop_id) do
    GenServer.call(__MODULE__, {:get_messages, prop_id})
  end

  @doc """
  Retorna todos los mensajes cuya propiedad pertenece a `username`.
  Consulta a PropertyManager para saber qué propiedades son del usuario.
  """
  def get_messages_for_owner(username) do
    GenServer.call(__MODULE__, {:get_messages_for_owner, username})
  end

  @doc "Retorna todos los mensajes enviados por un usuario"
  def get_messages_from(username) do
    GenServer.call(__MODULE__, {:get_messages_from, username})
  end

  # ---------------------------------------------------------------------------
  # CALLBACKS
  # ---------------------------------------------------------------------------

  @impl true
  def init(:ok) do
    ensure_storage!()
    {:ok, load()}
  end

  @impl true
  def handle_call({:send_message, from, prop_id, mensaje}, _from_pid, messages) do
    {fecha, hora} = current_datetime()

    nuevo = %__MODULE__{
      fecha:   fecha,
      hora:    hora,
      from:    from,
      prop_id: prop_id,
      mensaje: mensaje
    }

    append(nuevo)
    Logger.info("Mensaje de #{from} → prop #{prop_id}")
    {:reply, :ok, messages ++ [nuevo]}
  end

  @impl true
  def handle_call({:get_messages, prop_id}, _from_pid, messages) do
    filtrados = Enum.filter(messages, &(&1.prop_id == prop_id))
    {:reply, filtrados, messages}
  end

  @impl true
  def handle_call({:get_messages_for_owner, username}, _from_pid, messages) do
    # Obtener los prop_ids cuyo propietario sea username
    prop_ids =
      Inmobiliaria.PropertyManager.list(%{"propietario" => username})
      |> Enum.map(& &1.id)
      |> MapSet.new()

    filtrados = Enum.filter(messages, &MapSet.member?(prop_ids, &1.prop_id))
    {:reply, filtrados, messages}
  end

  @impl true
  def handle_call({:get_messages_from, username}, _from_pid, messages) do
    filtrados = Enum.filter(messages, &(&1.from == username))
    {:reply, filtrados, messages}
  end

  @impl true
  def handle_call(msg, from, messages) do
    Logger.warning("MessageManager: mensaje inesperado #{inspect(msg)} de #{inspect(from)}")
    {:reply, {:error, :unknown_command}, messages}
  end

  # ---------------------------------------------------------------------------
  # PERSISTENCIA (privado)
  # ---------------------------------------------------------------------------

  defp ensure_storage! do
    File.mkdir_p!("data")
    unless File.exists?(@path), do: File.write!(@path, "")
    :ok
  end

  defp load() do
    @path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.reject(&is_nil/1)
  end

  # Usar append para no reescribir todo el archivo en cada mensaje
  defp append(%__MODULE__{} = msg) do
    File.write!(@path, to_line(msg) <> "\n", [:append])
  end

  defp parse_line(line) do
    # Formato: fecha;hora;from=<u>;prop_id=<id>;mensaje=<texto>
    # El mensaje puede contener ";" así que usamos limit en el último split
    case String.split(line, ";", parts: 5) do
      [fecha, hora, from_kv, prop_kv, msg_kv] ->
        %__MODULE__{
          fecha:   fecha,
          hora:    hora,
          from:    strip_key(from_kv, "from"),
          prop_id: strip_key(prop_kv, "prop_id"),
          mensaje: strip_key(msg_kv, "mensaje")
        }
      _ ->
        Logger.warning("MessageManager: linea invalida -> #{line}")
        nil
    end
  end

  defp to_line(%__MODULE__{} = m) do
    "#{m.fecha};#{m.hora};from=#{m.from};prop_id=#{m.prop_id};mensaje=#{m.mensaje}"
  end

  # Quita el prefijo "key=" de un token
  defp strip_key(token, key) do
    String.replace_prefix(token, "#{key}=", "")
  end

  defp current_datetime() do
    now   = DateTime.utc_now()
    fecha = Date.to_string(DateTime.to_date(now))
    hora  = now |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)
    {fecha, hora}
  end
end
