defmodule Vocales do
  def contar_con_graphemes(cadena) do
    graph = String.graphemes(cadena)
    contar_lista(graph, 0)
  end

  defp contar_lista([], contador), do: contador
  defp contar_lista([h | t], contador) do
    if h in ["a", "e", "i", "o", "u", "á", "é", "í", "ó", "ú"] do
      contar_lista(t, contador + 1)
    else
      contar_lista(t, contador)
    end
  end
end

IO.puts Vocales.contar_con_graphemes("buenas")

"""
contar("hola")
  char='h' → no vocal → 0 + contar("ola")
    char='o' → vocal    → 1 + contar("la")
      char='l' → no vocal → 0 + contar("a")
        char='a' → vocal  → 1 + contar("")
          contar("") → 0
        retorna 1
      retorna 1
    retorna 2
  retorna 2
resultado: 2
"""
