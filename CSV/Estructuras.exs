defmodule Estructuras do
  def main do
    "clientes.csv"
    |> CSV.leer_csv(&Cliente.convertir_cadena_cliente/1)
    |> filtrar_datos_interes()
    |> CSV.generar_mensaje_csv(&generar_mensaje/1)
    |> Util.mostrar_mensaje()
  end

  defp filtrar_datos_interes(datos) do
    # Filtra solo clientes menores a 21 años
    Enum.filter(datos, &(&1.edad < 21))
  end

  defp generar_mensaje(cliente) do
    altura = Float.round(cliente.altura, 2)
    "Hola #{cliente.nombre}, tu edad es de #{cliente.edad} años y tienes una altura de #{altura}"
  end
end

Estructuras.main()
