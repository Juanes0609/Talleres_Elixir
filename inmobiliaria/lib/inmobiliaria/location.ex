defmodule Inmobiliaria.Location do
  @moduledoc """
  GenServer que gestiona las ubicaciones válidas del sistema.

  Responsabilidades:
    - Cargar ubicaciones desde locations.dat al iniciar (una por línea).
    - Validar que una ubicación exista antes de publicar una propiedad.
    - Permitir agregar nuevas ubicaciones en tiempo de ejecución.
    - Si locations.dat no existe, usar una lista por defecto del Quindío.

  Formato de locations.dat:
    Armenia
    Calarcá
    Montenegro
    ... (una ubicación por línea)
  """

  use GenServer
  require Logger

  @path Path.expand("data/locations.dat", File.cwd!())

  @ubicaciones_default [
    "Armenia", "Calarcá", "Montenegro", "La Tebaida",
    "Quimbaya", "Circasia", "Filandia", "Salento",
    "Pijao", "Génova", "Buenavista", "Córdoba"
  ]

  # ---------------------------------------------------------------------------
  # API PÚBLICA
  # ---------------------------------------------------------------------------

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @doc """
  Verifica si la ubicación existe en la lista (comparación case-insensitive).
  Retorna true | false
  """
  def valid_location?(ubicacion) do
    GenServer.call(__MODULE__, {:valid?, ubicacion})
  end

  @doc "Retorna la lista completa de ubicaciones válidas"
  def list_locations() do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Agrega una nueva ubicación y persiste en locations.dat.
  Retorna :ok | {:error, "La ubicacion ya existe"}
  """
  def add_location(ubicacion) do
    GenServer.call(__MODULE__, {:add, ubicacion})
  end

  # ---------------------------------------------------------------------------
  # CALLBACKS
  # ---------------------------------------------------------------------------

  @impl true
  def init(:ok) do
    ubicaciones = load()
    Logger.info("Location: #{length(ubicaciones)} ubicaciones cargadas")
    {:ok, ubicaciones}
  end

  @impl true
  def handle_call({:valid?, ubicacion}, _from, ubicaciones) do
    # Comparación case-insensitive
    normalizado = String.downcase(String.trim(ubicacion))
    existe = Enum.any?(ubicaciones, &(String.downcase(&1) == normalizado))
    {:reply, existe, ubicaciones}
  end

  @impl true
  def handle_call(:list, _from, ubicaciones) do
    {:reply, ubicaciones, ubicaciones}
  end

  @impl true
  def handle_call({:add, ubicacion}, _from, ubicaciones) do
    normalizado = String.downcase(String.trim(ubicacion))
    ya_existe   = Enum.any?(ubicaciones, &(String.downcase(&1) == normalizado))

    if ya_existe do
      {:reply, {:error, "La ubicacion '#{ubicacion}' ya existe"}, ubicaciones}
    else
      nuevas = ubicaciones ++ [String.trim(ubicacion)]
      flush(nuevas)
      Logger.info("Location: nueva ubicacion agregada -> #{ubicacion}")
      {:reply, :ok, nuevas}
    end
  end

  @impl true
  def handle_call(msg, from, ubicaciones) do
    Logger.warning("Location: mensaje inesperado #{inspect(msg)} de #{inspect(from)}")
    {:reply, {:error, :unknown_command}, ubicaciones}
  end

  # ---------------------------------------------------------------------------
  # PERSISTENCIA (privado)
  # ---------------------------------------------------------------------------

  defp load() do
    File.mkdir_p!("data")

    if File.exists?(@path) do
      @path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
    else
      # Crear el archivo con las ubicaciones por defecto
      flush(@ubicaciones_default)
      Logger.info("Location: locations.dat creado con ubicaciones por defecto del Quindio")
      @ubicaciones_default
    end
  end

  defp flush(ubicaciones) do
    File.mkdir_p!("data")
    File.write!(@path, Enum.join(ubicaciones, "\n") <> "\n")
  end
end
