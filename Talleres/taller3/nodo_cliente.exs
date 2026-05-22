defmodule Envio do
  defstruct id: "", tipo: "", distancia: 0, costo_base: 0

  defmodule NodoCliente do
    @nombre_servicio_local :servicio_respuesta
    @nodo_remoto :"nodo_servidor@172.20.10.5"
    @servicio_remoto {:servicio_cadenas, @nodo_remoto}

    def enviar_pedido do
      if Process.whereis(@nombre_servicio_local), do: Process.unregister(@nombre_servicio_local)

      Process.register(self(), @nombre_servicio_local)

      envio = %Envio{id: "TX", tipo: "INTERNACIONAL", distancia: 350, costo_base: 80}

      send(@servicio_remoto, {envio, self()})

      receive do
        {:costo_calculado, costo} ->
          IO.puts("----LOGÍSTICA CLIENTE----")
          IO.puts("Costo total recibido desde el servidor: $#{costo}")
      end
    end
  end
end
