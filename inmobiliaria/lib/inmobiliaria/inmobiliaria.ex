defmodule Inmobiliaria.Application do
  @moduledoc """
  Árbol de supervisión (OTP Tree):
    Inmobiliaria.Supervisor              (one_for_one)
    ├── Registry                         (Inmobiliaria.PropertyRegistry)
    ├── Inmobiliaria.Location
    ├── Inmobiliaria.UserManager
    ├── Inmobiliaria.MessageManager
    ├── Inmobiliaria.PropertyManager
    ├── Inmobiliaria.PropertySupervisor  (DynamicSupervisor)
    └── Inmobiliaria.Server
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Iniciando sistema inmobiliario...")

    children = [
      # Registry para localizar procesos de propiedades por su id
      # Permite hacer: {:via, Registry, {Inmobiliaria.PropertyRegistry, "prop001"}}
      {Registry, keys: :unique, name: Inmobiliaria.PropertyRegistry},

      # Carga ubicaciones válidas desde locations.dat
      {Inmobiliaria.Location, name: Inmobiliaria.Location},

      # Gestión de usuarios: registro, login, puntajes, rankings
      {Inmobiliaria.UserManager, name: Inmobiliaria.UserManager},

      # Gestión de mensajería entre clientes y propietarios
      {Inmobiliaria.MessageManager, name: Inmobiliaria.MessageManager},

      # DynamicSupervisor: un proceso GenServer por cada propiedad activa
      # Si un proceso de propiedad falla, solo ese se reinicia (one_for_one)
      {DynamicSupervisor, strategy: :one_for_one, name: Inmobiliaria.PropertySupervisor},

      # Registro y consulta de propiedades, coordina compras/arriendos
      {Inmobiliaria.PropertyManager, name: Inmobiliaria.PropertyManager},

      # Servidor principal: recibe y despacha comandos del CLI
      {Inmobiliaria.Server, []}
    ]

    opts = [strategy: :one_for_one, name: Inmobiliaria.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
