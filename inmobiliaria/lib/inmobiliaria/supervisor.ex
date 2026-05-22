defmodule Inmobiliaria.PropertySupervisor do
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_property(property) do
    DynamicSupervisor.start_child(__MODULE__, {Inmobiliaria.Property, property})
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
