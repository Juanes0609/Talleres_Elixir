defmodule Inmobiliaria.UserManager do
  use GenServer
  require Logger

  @path Path.expand("data/users.dat", File.cwd!())

  @roles_validos ["cliente", "vendedor", "arrendador"]

  # Puntos por operación
  @puntos_cliente 10
  @puntos_vendedor 15
  @puntos_arrendador 12

  # ---------------------------------------------------------------------------
  # API PÚBLICA
  # ---------------------------------------------------------------------------

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  def connect(username, password, role) do
    GenServer.call(__MODULE__, {:connect, username, password, role})
  end

  def add_score(username, delta) do
    GenServer.call(__MODULE__, {:add_score, username, delta})
  end

  @doc "Retorna el puntaje actual del usuario"
  def get_score(username) do
    GenServer.call(__MODULE__, {:get_score, username})
  end

  @doc "Ranking global de los top_n usuarios con más puntos"
  def ranking(top_n \\ 10) do
    GenServer.call(__MODULE__, {:ranking, top_n})
  end

  @doc "Ranking filtrado por rol (\"cliente\", \"vendedor\" o \"arrendador\")"
  def ranking_por_rol(role, top_n \\ 10) do
    GenServer.call(__MODULE__, {:ranking_por_rol, role, top_n})
  end

  @doc "Puntos estándar según el rol del usuario en la operación"
  def puntos_para(:cliente), do: @puntos_cliente
  def puntos_para(:vendedor), do: @puntos_vendedor
  def puntos_para(:arrendador), do: @puntos_arrendador

  # ---------------------------------------------------------------------------
  # CALLBACKS DEL GENSERVER
  # ---------------------------------------------------------------------------

  @impl true
  def init(:ok) do
    ensure_storage!()
    {:ok, load()}
  end

  # connect: registrar o autenticar
  @impl true
  def handle_call({:connect, username, password, role}, _from, store)
      when role in @roles_validos do
    case Map.fetch(store, username) do
      # Usuario ya existe -> validar contraseña y rol
      {:ok, {rol_guardado, pass_guardada, score}} ->
        if pass_guardada == password and rol_guardado == role do
          user = %{username: username, role: rol_guardado, score: score}
          {:reply, {:ok, user}, store}
        else
          {:reply, {:error, :credenciales_invalidas}, store}
        end

      # Usuario no existe -> registrar automáticamente
      :error ->
        nuevo_usuario = {role, password, 0}
        nuevo_store = Map.put(store, username, nuevo_usuario)
        flush(nuevo_store)
        Logger.info("Nuevo usuario registrado: #{username} (#{role})")
        user = %{username: username, role: role, score: 0}
        {:reply, {:ok, user}, nuevo_store}
    end
  end

  # Rol inválido
  def handle_call({:connect, _u, _p, role}, _from, store) do
    msg = "Rol '#{role}' invalido. Usa: cliente, vendedor o arrendador"
    {:reply, {:error, msg}, store}
  end

  # add_score
  @impl true
  def handle_call({:add_score, username, delta}, _from, store) do
    case Map.fetch(store, username) do
      {:ok, {role, pass, score}} ->
        nuevo_score = score + delta
        nuevo_store = Map.put(store, username, {role, pass, nuevo_score})
        flush(nuevo_store)
        {:reply, {:ok, nuevo_score}, nuevo_store}

      :error ->
        {:reply, {:error, :not_found}, store}
    end
  end

  # get_score
  @impl true
  def handle_call({:get_score, username}, _from, store) do
    case Map.fetch(store, username) do
      {:ok, {_, _, score}} -> {:reply, {:ok, score}, store}
      :error -> {:reply, {:error, :not_found}, store}
    end
  end

  # ranking global
  @impl true
  def handle_call({:ranking, top_n}, _from, store) do
    ranking =
      store
      |> Enum.map(fn {u, {r, _p, s}} -> %{username: u, role: r, score: s} end)
      |> Enum.sort_by(& &1.score, :desc)
      |> Enum.take(top_n)

    {:reply, ranking, store}
  end

  # ranking por rol
  @impl true
  def handle_call({:ranking_por_rol, role, top_n}, _from, store) do
    ranking =
      store
      |> Enum.map(fn {u, {r, _p, s}} -> %{username: u, role: r, score: s} end)
      |> Enum.filter(&(&1.role == role))
      |> Enum.sort_by(& &1.score, :desc)
      |> Enum.take(top_n)

    {:reply, ranking, store}
  end

  # fallback
  @impl true
  def handle_call(msg, from, store) do
    Logger.warning("UserManager: mensaje inesperado #{inspect(msg)} de #{inspect(from)}")
    {:reply, {:error, :unknown_command}, store}
  end

  # ---------------------------------------------------------------------------
  # PERSISTENCIA (privado)
  # ---------------------------------------------------------------------------

  def ensure_storage! do
    File.mkdir_p!("data")
    unless File.exists?(@path), do: File.write!(@path, "")
    :ok
  end

  # Lee users.dat y retorna mapa %{username => {role, password, score}}
  defp load() do
    ensure_storage!()

    @path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # Parsea una línea "username;role;password;score"
  defp parse_line(line) do
    case String.split(line, ";") do
      [u, r, p, s] ->
        score =
          case Integer.parse(s) do
            {n, _} -> n
            :error -> 0
          end

        {u, {r, p, score}}

      [u, r, p] ->
        {u, {r, p, 0}}

      _ ->
        Logger.warning("UserManager: linea invalida en users.dat -> #{line}")
        nil
    end
  end

  # Serializa una entrada del mapa a línea de texto
  defp serialize({username, {role, password, score}}) do
    Enum.join([username, role, password, Integer.to_string(score)], ";")
  end

  # Reescribe users.dat completo con el estado actual
  defp flush(store) do
    body =
      store
      |> Enum.map(&serialize/1)
      |> Enum.join("\n")

    contenido = if body == "", do: "", else: body <> "\n"
    File.write!(@path, contenido)
    :ok
  end
end
