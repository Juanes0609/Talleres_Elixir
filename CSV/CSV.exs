defmodule CSV do
  def leer_csv(nombre, parser) do
    nombre
    |> File.stream!()
    |> Stream.drop(1)
    |> Enum.map(parser)
  end

  def generar_mensaje_csv(datos, parser) do
    datos
    |> Enum.map(parser)
    |> Enum.join("\n")
  end

  def escribir_csv(datos, nombre, titulos, parser) do
    datos
    |> generar_mensaje_csv(parser)
    |> (&(titulos <> "\n" <> &1)).()
    |> (&File.write(nombre, &1)).()
  end
end
