defmodule MasLarga do
  def mas_larga([unica]), do: unica
  def mas_larga([h | t]) do
    candidata = mas_larga(t)
    if String.length(h) >= String.length(candidata), do: h, else: candidata
  end
end

"""
mas_larga(["sol", "murciélago", "luna"])
  mas_larga(["murciélago", "luna"])
    mas_larga(["luna"])
      retorna "luna"
    "murciélago"(10) >= "luna"(4) → retorna "murciélago"
  "sol"(3) >= "murciélago"(10)? No → retorna "murciélago"
resultado: "murciélago"
"""
