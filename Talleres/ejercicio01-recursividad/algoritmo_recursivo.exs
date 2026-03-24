defmodule Calculadora do
  def sum_dv([]), do: 0
  def sum_dv([elemento]), do: elemento

  defp sum_dv(lista) do
    mitad = div(length(lista), 2)
    {izquierda, derecha} = Enum.split(lista, mitad)

    sum_dv(izquierda) + sum_dv(derecha)
  end
end

IO.puts([1,2,3,4,5])
