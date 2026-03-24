Code.require_file("../problema-01/util.ex")

defmodule ImpresorLista do
  def main do
    n = Util.ingresar("Ingrese el hasta que número va la lista: ", :entero)
    lista = Enum.to_list(1..n)

    imprimir_rango(lista)
    end

    defp imprimir_rango([]), do: :ok

    defp imprimir_rango([head, x | tail]) do
      IO.puts("Número: #{head} #{x}")
      imprimir_rango(tail)
    end
  end

ImpresorLista.main()
