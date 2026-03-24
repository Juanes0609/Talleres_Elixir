Code.require_file("../problema-01/util.ex")

defmodule Matrushka do
  def main do
    n = Util.ingresar("Ingrese el numero de matrushkas (mayor a 0): ", :entero)
    imprimir_matrushka(n)
  end
  defp imprimir_matrushka(0), do: :ok

  defp  imprimir_matrushka(n)do
    IO.puts("abriendo matrushka #{n}")
    imprimir_matrushka(n-1)
    IO.puts("cerrando matrushka #{n}")
  end
end

Matrushka.main()


