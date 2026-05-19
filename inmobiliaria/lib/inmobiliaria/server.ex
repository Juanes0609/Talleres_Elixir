defmodule Inmobiliaria.Server do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def connect(username, password, role) do
    GenServer.call(__MODULE__, {:connect, username, password, role})
  end

  def disconnect(username) do
    GenServer.call(__MODULE__, {:disconnect, username})
  end

  def publish_property(username, attrs) do
    GenServer.call(__MODULE__, {:publish_property, username, attrs})
  end

  def list_properties(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list_properties, filters})
  end

  def buy_property(username, prop_id) do
    GenServer.call(__MODULE__, {:buy_property, username, prop_id})
  end

  def rent_property(username, prop_id) do
    GenServer.call(__MODULE__, {:rent_property, username, prop_id})
  end

  def reserve_property(username, prop_id) do
    GenServer.call(__MODULE__, {:reserve_property, username, prop_id})
  end

  def cancel_property(username, prop_id) do
    GenServer.call(__MODULE__, {:cancel_property, username, prop_id})
  end

  def send_message(username, prop_id, mensaje) do
    GenServer.call(__MODULE__, {:send_message, username, prop_id, mensaje})
  end

  def read_messages(username, prop_id) do
    GenServer.call(__MODULE__, {:read_messages, username, prop_id})
  end

  def my_score(username), do: Inmobiliaria.UserManager.get_score(username)
  def ranking(), do: Inmobiliaria.UserManager.ranking(20)
  def ranking_compradores(), do: Inmobiliaria.UserManager.ranking_por_rol("cliente", 20)
  def ranking_vendedores(), do: Inmobiliaria.UserManager.ranking_por_rol("vendedor", 20)
  def ranking_arrendadores(), do: Inmobiliaria.UserManager.ranking_por_rol("arrendador", 20)
  def list_locations(), do: Inmobiliaria.Location.list_locations()

  # ---------------------------------------------------------------------------
  # INIT
  # ---------------------------------------------------------------------------

  @impl true
  def init(_) do
    # sessions guarda los usuarios conectados en esta sesión
    # %{"ana" => %{role: "cliente"}, "carlos" => %{role: "vendedor"}}
    {:ok, %{sessions: %{}}}
  end

  # ---------------------------------------------------------------------------
  # CALLBACKS
  # ---------------------------------------------------------------------------

  # --- connect ---
  @impl true
  def handle_call({:connect, username, password, role}, _from, state) do
    Inmobiliaria.UserManager.ensure_storage!()

    case Inmobiliaria.UserManager.connect(username, password, role) do
      {:ok, user} ->
        nueva_sesion = put_in(state, [:sessions, username], %{role: role})
        Logger.info("Usuario conectado: #{username} (#{role})")
        {:reply, {:ok, user}, nueva_sesion}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # --- disconnect ---
  @impl true
  def handle_call({:disconnect, username}, _from, state) do
    nuevo_state = update_in(state, [:sessions], &Map.delete(&1, username))
    Logger.info("Usuario desconectado: #{username}")
    {:reply, :ok, nuevo_state}
  end

  # --- publish_property ---
  @impl true
  def handle_call({:publish_property, username, attrs}, _from, state) do
    cond do
      # Verificar sesión activa
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      # Solo vendedores y arrendadores pueden publicar
      state.sessions[username].role not in ["vendedor", "arrendador"] ->
        {:reply, {:error, "Solo vendedores y arrendadores pueden publicar propiedades"}, state}

      # Validar ubicacion
      not Inmobiliaria.Location.valid_location?(attrs[:ubicacion] || attrs["ubicacion"]) ->
        {:reply, {:error, "Ubicacion invalida. Usa list_locations para ver las disponibles"},
         state}

      true ->
        case Inmobiliaria.PropertyManager.publish(username, attrs) do
          {:ok, property} ->
            {:reply, {:ok, property}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  # --- list_properties ---
  @impl true
  def handle_call({:list_properties, filters}, _from, state) do
    propiedades = Inmobiliaria.PropertyManager.list(filters)
    {:reply, propiedades, state}
  end

  # --- buy_property ---
  @impl true
  def handle_call({:buy_property, username, prop_id}, _from, state) do
    cond do
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      state.sessions[username].role != "cliente" ->
        {:reply, {:error, "Solo los clientes pueden comprar propiedades"}, state}

      true ->
        case Inmobiliaria.PropertyManager.buy(prop_id, username) do
          {:ok, property} ->
            {:reply, {:ok, property}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  # --- rent_property ---
  @impl true
  def handle_call({:rent_property, username, prop_id}, _from, state) do
    cond do
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      state.sessions[username].role != "cliente" ->
        {:reply, {:error, "Solo los clientes pueden arrendar propiedades"}, state}

      true ->
        case Inmobiliaria.PropertyManager.rent(prop_id, username) do
          {:ok, property} ->
            {:reply, {:ok, property}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  # --- reserve_property ---
  @impl true
  def handle_call({:reserve_property, username, prop_id}, _from, state) do
    cond do
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      state.sessions[username].role != "cliente" ->
        {:reply, {:error, "Solo los clientes pueden reservar propiedades"}, state}

      true ->
        case Inmobiliaria.PropertyManager.reserve(prop_id, username) do
          {:ok, property} -> {:reply, {:ok, property}, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
    end
  end

  # --- cancel_property ---
  @impl true
  def handle_call({:cancel_property, username, prop_id}, _from, state) do
    cond do
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      state.sessions[username].role != "cliente" ->
        {:reply, {:error, "Solo los clientes pueden cancelar"}, state}

      true ->
        case Inmobiliaria.PropertyManager.cancel(prop_id, username) do
          {:ok, property} -> {:reply, {:ok, property}, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
    end
  end

  # --- send_message ---
  @impl true
  def handle_call({:send_message, username, prop_id, mensaje}, _from, state) do
    case Map.has_key?(state.sessions, username) do
      false ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      true ->
        case Inmobiliaria.MessageManager.send_message(username, prop_id, mensaje) do
          :ok -> {:reply, :ok, state}
          {:error, r} -> {:reply, {:error, r}, state}
        end
    end
  end

  # --- read_messages ---
  @impl true
  def handle_call({:read_messages, username, prop_id}, _from, state) do
    cond do
      not Map.has_key?(state.sessions, username) ->
        {:reply, {:error, "Debes conectarte primero"}, state}

      state.sessions[username].role not in ["vendedor", "arrendador"] ->
        {:reply, {:error, "Solo vendedores y arrendadores pueden leer mensajes de propiedades"},
         state}

      true ->
        mensajes = Inmobiliaria.MessageManager.get_messages(prop_id)
        {:reply, mensajes, state}
    end
  end

  # fallback
  @impl true
  def handle_call(msg, from, state) do
    Logger.warning("Server: mensaje inesperado #{inspect(msg)} de #{inspect(from)}")
    {:reply, {:error, :unknown_command}, state}
  end

  # ---------------------------------------------------------------------------
  # CLI — Loop interactivo desde la terminal
  # ---------------------------------------------------------------------------

  @doc """
  Inicia el loop interactivo de la línea de comandos.
  Ejecutar con: iex -S mix → Inmobiliaria.Server.start_cli()
  O directamente con: mix run --no-halt
  """
  def start_cli() do
    IO.puts("""
    ============================================
     Bienvenido al Sistema Inmobiliario Elixir
    ============================================
    Escribe 'help' para ver los comandos disponibles.
    Escribe 'exit' para salir.
    """)

    cli_loop(nil)
  end

  defp cli_loop(usuario_activo) do
    input = IO.gets("inmobiliaria> ") |> String.trim()

    case input do
      "exit" ->
        if usuario_activo, do: disconnect(usuario_activo)
        IO.puts("Hasta pronto.")

      "" ->
        cli_loop(usuario_activo)

      _ ->
        nuevo_usuario = despachar_comando(input, usuario_activo)
        cli_loop(nuevo_usuario)
    end
  end

  defp despachar_comando(input, usuario_activo) do
    tokens = String.split(input, " ", trim: true)

    case tokens do
      ["connect", u, p, r] ->
        case connect(u, p, r) do
          {:ok, _user} ->
            IO.puts("=> Conexión exitosa. Bienvenido, #{u}.")
            u

          {:error, err} ->
            IO.puts("=> Error: #{inspect(err)}")
            usuario_activo
        end

      ["disconnect"] ->
        if usuario_activo do
          disconnect(usuario_activo)
          IO.puts("=> Sesión cerrada.")
        end

        nil

      ["buy_property", prop_id] ->
        if usuario_activo,
          do: IO.inspect(buy_property(usuario_activo, prop_id)),
          else: IO.puts("=> Conéctate primero.")

        usuario_activo

      ["rent_property", prop_id] ->
        if usuario_activo,
          do: IO.inspect(rent_property(usuario_activo, prop_id)),
          else: IO.puts("=> Conéctate primero.")

        usuario_activo

      ["reserve_property", prop_id] ->
        if usuario_activo,
          do: IO.inspect(reserve_property(usuario_activo, prop_id)),
          else: IO.puts("=> Conéctate primero.")

        usuario_activo

      ["cancel_property", prop_id] ->
        if usuario_activo,
          do: IO.inspect(cancel_property(usuario_activo, prop_id)),
          else: IO.puts("=> Conéctate primero.")

        usuario_activo

      ["my_score"] ->
        defp despachar_comando(input, usuario_activo) do
          tokens = String.split(input, " ", trim: true)

          case tokens do
            ["connect", u, p, r] ->
              case connect(u, p, r) do
                {:ok, _user} ->
                  IO.puts("=> Conexión exitosa. Bienvenido, #{u}.")
                  u

                {:error, err} ->
                  IO.puts("=> Error: #{inspect(err)}")
                  usuario_activo
              end

            ["disconnect"] ->
              if usuario_activo do
                disconnect(usuario_activo)
                IO.puts("=> Sesión cerrada.")
              end

              nil

            ["buy_property", prop_id] ->
              if usuario_activo,
                do: IO.inspect(buy_property(usuario_activo, prop_id)),
                else: IO.puts("=> Conéctate primero.")

              usuario_activo

            ["rent_property", prop_id] ->
              if usuario_activo,
                do: IO.inspect(rent_property(usuario_activo, prop_id)),
                else: IO.puts("=> Conéctate primero.")

              usuario_activo

            ["reserve_property", prop_id] ->
              if usuario_activo,
                do: IO.inspect(reserve_property(usuario_activo, prop_id)),
                else: IO.puts("=> Conéctate primero.")

              usuario_activo

            ["cancel_property", prop_id] ->
              if usuario_activo,
                do: IO.inspect(cancel_property(usuario_activo, prop_id)),
                else: IO.puts("=> Conéctate primero.")

              usuario_activo

            ["my_score"] ->
              if usuario_activo,
                do: IO.inspect(my_score(usuario_activo)),
                else: IO.puts("=> Conéctate primero.")

              usuario_activo

            ["ranking"] ->
              IO.inspect(ranking())
              usuario_activo

            ["help"] ->
              # Asegúrate de que esta función exista mostrando todos los comandos
              imprimir_ayuda()
              usuario_activo

            # Comando genérico para comandos que faltan (publish_property, etc.)
            _ ->
              IO.puts("=> Comando no reconocido o faltan argumentos. Usa 'help'.")
              usuario_activo
          end
        end

        if usuario_activo,
          do: IO.inspect(my_score(usuario_activo)),
          else: IO.puts("=> Conéctate primero.")

        usuario_activo

      ["ranking"] ->
        IO.inspect(ranking())
        usuario_activo

      ["help"] ->
        # Asegúrate de que esta función exista mostrando todos los comandos
        imprimir_ayuda()
        usuario_activo

      # Comando genérico para comandos que faltan (publish_property, etc.)
      _ ->
        IO.puts("=> Comando no reconocido o faltan argumentos. Usa 'help'.")
        usuario_activo
    end
  end

  # ---------------------------------------------------------------------------
  # HELPERS DE FORMATO
  # ---------------------------------------------------------------------------

  defp parse_kv(tokens) do
    Enum.reduce(tokens, %{}, fn token, acc ->
      case String.split(token, "=", parts: 2) do
        [k, v] -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
  end

  defp imprimir_propiedad(p) do
    IO.puts("""
    ------------------------------------------
    ID: #{p.id} | #{p.tipo} en #{p.modalidad}
    Ubicacion: #{p.ubicacion} | Precio: $#{p.precio}
    Habitaciones: #{p.habitaciones} | Area: #{p.area} m2
    Estado: #{p.estado} | Propietario: #{p.propietario}
    ------------------------------------------
    """)
  end

  defp imprimir_mensaje(m) do
    IO.puts("[#{m.fecha} #{m.hora}] #{m.from}: #{m.mensaje}")
  end

  defp imprimir_ranking(lista, titulo) do
    IO.puts("\n=== #{titulo} ===")

    if lista == [] do
      IO.puts("  (sin datos)")
    else
      lista
      |> Enum.with_index(1)
      |> Enum.each(fn {%{username: u, role: r, score: s}, i} ->
        IO.puts("  #{i}. #{u} (#{r}) — #{s} pts")
      end)
    end

    IO.puts("")
  end

  defp imprimir_ayuda() do
    IO.puts("""

    === Comandos disponibles ===

    SESION:
      connect <usuario> <clave> <rol>      Conectarse (rol: cliente | vendedor | arrendador)
      disconnect                           Cerrar sesion

    PROPIEDADES:
      publish_property tipo=<t> modalidad=<m> ubicacion=<u> precio=<p> habitaciones=<h> area=<a>
                                           Publicar propiedad (vendedor/arrendador)
      list_properties [tipo=<t>] [modalidad=<m>] [ubicacion=<u>] [precio_min=<n>] [precio_max=<n>]
                                           Listar propiedades con filtros opcionales
      buy_property <prop_id>              Comprar propiedad (cliente)
      rent_property <prop_id>             Arrendar propiedad (cliente)

    MENSAJERIA:
      send_message <prop_id> <mensaje>    Enviar mensaje al propietario
      read_messages <prop_id>             Ver mensajes de una propiedad (vendedor/arrendador)

    PUNTAJES Y RANKINGS:
      my_score                            Ver tu puntaje actual
      ranking                             Ranking global
      ranking_compradores                 Ranking de clientes
      ranking_vendedores                  Ranking de vendedores
      ranking_arrendadores                Ranking de arrendadores

    OTROS:
      list_locations                      Ver ubicaciones validas
      help                                Mostrar esta ayuda
      exit                                Salir del sistema
    """)
  end
end
