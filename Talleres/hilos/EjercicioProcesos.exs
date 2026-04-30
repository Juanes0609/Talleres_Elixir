defmodule Matrix do
  def main do

    matrix = [
      [60, 22, 41,5],
      [13, 33, 44,5],
      [89, 10, 100, 99],
      [5, 101, 6, 34]
    ]

    Process.sleep(500)
    t1 = Task.async(fn -> s1(matrix) end)
    t2 = Task.async(fn -> s2(matrix) end)

    a = Task.await(t1)
    b = Task.await(t2)

    c = a*b

    IO.puts("a: #{a}")
    IO.puts("b: #{b}")
    IO.puts("c: #{c}")

  end

  defp s1(matrix) do
    matrix
    |> Enum.with_index()
    |> Enum.flat_map(fn {fila, i} ->
      Enum.take(fila, i)
    end)
    |> Enum.sum()
  end


  defp s2(matrix) do
    {suma, cantidad} = calcular_suma_cantidad(matrix, 0, 0)

    suma / cantidad
  end

  # Caso 1
  defp calcular_suma_cantidad([], suma, cantidad), do: {suma, cantidad}

  # Caso 2, donde la fila viene vacía
  defp calcular_suma_cantidad([[] | resto], suma, cantidad), do: calcular_suma_cantidad(resto, suma, cantidad)

  defp calcular_suma_cantidad([[num | resto_fila] | resto], suma, cantidad) do
    nueva_matriz = [resto_fila | resto]
    calcular_suma_cantidad(nueva_matriz, suma + num, cantidad + 1)

  end
end

Matrix.main()
