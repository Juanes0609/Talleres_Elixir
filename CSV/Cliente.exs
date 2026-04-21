defmodule Cliente do
  defstruct nombre: "", edad: 0, altura: 0.0

  def crear(nombre, edad, altura) do
    %Cliente{nombre: nombre, edad: edad, altura: altura}
  end

  def convertir_cadena_cliente(cadena) do
    [nombre, edad, altura] =
      cadena
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    crear(nombre, String.to_integer(edad), String.to_float(altura))
  end

  def convertir_cliente_linea_csv(cliente) do
    "#{cliente.nombre}, #{cliente.edad}, #{cliente.altura}"
  end
end
