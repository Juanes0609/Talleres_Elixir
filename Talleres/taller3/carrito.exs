defmodule Item do
  defstruct id: "",
            nombre: "",
            cantidad: 0,
            precio_unitario: 0
end

defmodule Carrito do
  def main() do
    items_iniciales = leer_csv()
    spawn(fn -> loop(items_iniciales) end)
  end

  def loop(items) do
    receive do
      {:agregar_item, item} ->
        nuevos_items = agregar_item(items, item)
        loop(nuevos_items)

      {:quitar_item, id} ->
        nuevo_items = quitar_item(items, id)
        loop(nuevos_items)
!
      {:total, pid} ->
        total = calcular_total(items, pid)
        loop(items)

      {:listar, pid} ->
        send(pid, {:lista, items})
        loop(items)

      :guardar_archivo ->
        guardar_csv(items)
        loop(items)

      :vaciar ->
        loop([])

      :detener ->
        :ok
    end
  end

  defp agregar_item(items, item) do
    case Enum.find_index(items, &(&1.id == item.id)) do
      nil ->
        items ++ [item]

      idx ->
        List.update_at(items, idx, fn i ->
          %{i | cantidad: i.cantidad + item.cantidad}
        end)
    end
  end

  defp quitar_item(items, id) do
    nueva_lista = Enum.filter(items, fn i -> i.id != id end)

    if length(nueva_lista) == length(items) do
      IO.puts("No se encontró ningun item con ese id.")
      items
    else
      nueva_lista
    end
  end

  defp calcular_total(items, pid) do
    total = Enum.reduce(items, 0, fn i, acc -> acc + i.cantidad * i.precio_unitario end)
    send(pid, {:total, total})
  end
end
