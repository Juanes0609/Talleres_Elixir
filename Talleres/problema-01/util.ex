defmodule Util do
  def mostrar_mensaje(mensaje) do
    IO.puts(mensaje)
  end

  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  # def ingresar(mensaje, :entero) do
  #   mensaje
  #   |> Util.ingresar(:texto)
  #   |> String.to_integer()
  # end

  # def ingresar(mensaje, :real) do
  #   mensaje
  #   |> Util.ingresar(:texto)
  #   |> String.to_float()
  # end

  # def ingresar(mensaje, :entero) do
  #   try do
  #     mensaje
  #     |> ingresar(:texto)
  #     |> String.to_integer()
  #   rescue
  #     ArgumentError ->
  #       "Error, se espera que ingrese un entero\n"
  #       |> mostrar_error()

  #       mensaje
  #       |> ingresar(:entero)
  #   end
  # end

  def ingresar(mensaje, :entero), do: ingresar(mensaje, &String.to_integer/1, :entero)

  def ingresar(mensaje, :real), do: ingresar(mensaje, &String.to_float()/1, :real)

  defp ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un numero #{tipo_dato}"
        |> mostrar_error()
        ingresar(mensaje, parser, tipo_dato)
    end
  end

  def mostrar_error(mensaje), do: IO.puts(:standard_error, mensaje)

  def ingresar(mensaje, :boolean) do
    valor =
    mensaje
    |> ingresar(:texto)
    |> String.downcase()
    Enum.member?(["si", "sí", "s"], valor)
  end
end
