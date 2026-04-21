defmodule Potencia do
  def es_potencia?(1, _b), do: true
  def es_potencia?(_n, 1), do: false
  def es_potencia?(n, _b) when n <= 0, do: false

  def es_potencia?(n, b) do
    if rem(n, b) == 0 do
      es_potencia?(div(n, b), b)
    else
      false
    end
  end
end

IO.puts Potencia.es_potencia?(8, 2)

"""
es_potencia?(16, 2) → rem(16,2)=0 → es_potencia?(8, 2)
  es_potencia?(8, 2)  → rem(8,2)=0  → es_potencia?(4, 2)
    es_potencia?(4, 2)  → rem(4,2)=0  → es_potencia?(2, 2)
      es_potencia?(2, 2)  → rem(2,2)=0  → es_potencia?(1, 2)
        es_potencia?(1, _) → true
      retorna true
    retorna true
  retorna true
resultado: true
"""
