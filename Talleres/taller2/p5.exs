defmodule Reversible do

  # Entrada principal con validación
  def es_reversible?(n) when n <= 0, do: {:error, "El número debe ser un entero positivo"}
  def es_reversible?(n) do
    invertido = invertir(n, 0)
    suma = n + invertido
    todos_impares?(suma)
  end

  # Invierte los dígitos: invertir(36, 0) → 63
  defp invertir(0, acc), do: acc
  defp invertir(n, acc) do
    invertir(div(n, 10), acc * 10 + rem(n, 10))
  end

  # Verifica que todos los dígitos sean impares
  defp todos_impares?(0), do: true
  defp todos_impares?(n) do
    digito = rem(n, 10)
    if rem(digito, 2) == 1 do
      todos_impares?(div(n, 10))
    else
      false
    end
  end
end

"""
Ejemplo con 36:

invertir(36, 0):
  invertir(3, 0*10 + 6) = invertir(3, 6)
  invertir(0, 6*10 + 3) = invertir(0, 63)
  → retorna 63

suma = 36 + 63 = 99

todos_impares?(99):
  digito = rem(99,10) = 9 → impar → todos_impares?(9)
  digito = rem(9,10)  = 9 → impar → todos_impares?(0)
  → retorna true

resultado: true ✓
"""

"""
Ejemplo ivertido con 12:

invertir(12) → 21
suma = 12 + 21 = 33
todos_impares?(33):
  digito = 3 → impar → todos_impares?(3)
  digito = 3 → impar → todos_impares?(0)
  → true  ← 12 también es reversible

Probemos con 11:
  invertir(11) → 11
  suma = 22
  todos_impares?(22):
    digito = 2 → par → false ✓
"""
