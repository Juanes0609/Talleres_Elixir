defmodule Recurs do
  def agrupar(lista), do: do_agrupar(lista, [])

  defp do_agrupar([], acc), do: acc |> Enum.reverse() |> List.to_tuple()

  defp do_agrupar([h], acc), do: do_agrupar([], [[h] | acc])

  defp do_agrupar([h1, h2 | resto], acc) do
    do_agrupar(resto, [[h1,h2] | acc])
  end

  def mayores_a_diez(lista), do: do_mayores_a_diez(lista, [])

  defp do_mayores_a_diez([], acc), do: acc

  defp do_mayores_a_diez([h | t], acc) when h > 10, do: do_mayores_a_diez(t, [h | acc])

  defp do_mayores_a_diez([_h | t], acc), do: do_mayores_a_diez(t, acc)

  def devolver_pares_impares(lista), do: do_tupla()

  end

IO.inspect(Recurs.mayores_a_diez([5,12,9,22]))
