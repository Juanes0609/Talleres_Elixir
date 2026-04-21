defmodule Perfecto do
  def es_perfecto?(n) when n <= 1, do: false
  
  def es_perfecto?(n) do
    suma_divisores(n, 1, 0) == n
  end

  # Acumulador: divisor actual, suma acumulada
  defp suma_divisores(n, divisor, acc) when divisor >= n, do: acc
  defp suma_divisores(n, divisor, acc) do
    nuevo_acc = if rem(n, divisor) == 0, do: acc + divisor, else: acc
    suma_divisores(n, divisor + 1, nuevo_acc)
  end
end

"""
suma_divisores(6, 1, 0) → rem(6,1)=0 → suma_divisores(6, 2, 1)
suma_divisores(6, 2, 1) → rem(6,2)=0 → suma_divisores(6, 3, 3)
suma_divisores(6, 3, 3) → rem(6,3)=0 → suma_divisores(6, 4, 6)
suma_divisores(6, 4, 6) → rem(6,4)≠0 → suma_divisores(6, 5, 6)
suma_divisores(6, 5, 6) → rem(6,5)≠0 → suma_divisores(6, 6, 6)
suma_divisores(6, 6, 6) → divisor >= n → retorna 6
6 == 6 → true ✓
"""
