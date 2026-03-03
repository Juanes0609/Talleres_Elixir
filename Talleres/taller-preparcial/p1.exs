Code.require_file("../problema-01/util.ex")

defmodule Reservas do
  def main do
    noches = Util.ingresar("Ingrese número de noches: ", :entero)

    input_tipo =
      Util.ingresar(
        "Tipo de Cliente\n 1: Frecuente\n 2: Corporativo\n 3: Ocasional\nIngresar número: ",
        :entero
      )

    tipo =
      case input_tipo do
        1 -> :frecuente
        2 -> :corporativo
        _ -> :ocasional
      end

    temp = Util.ingresar("Temporada (1: Alta, 2: Baja): ", :entero)
    calcular(noches, tipo, temp)
  end

  def calcular(noches, tipo, temp) do
    tarifa_base = calc_tarifa_base(noches)

    subtotal = tarifa_base * noches

    valor_descuento = calcular_descuento(subtotal, tipo)

    porcentaje_recargo =
      case temp do
        1 -> 0.25
        2 -> 0.0
        _ -> :error
      end

    if porcentaje_recargo == :error do
      Util.mostrar_error("Temporada incorrecta. Ingrese 1 para Alta o 2 para Baja.")
    else
      valor_recargo = subtotal * porcentaje_recargo
      total = subtotal - valor_descuento + valor_recargo

      resultado = {tarifa_base, subtotal, valor_descuento, valor_recargo, total}

      mostrar_mensaje(resultado)

      resultado
    end
  end

  defp calc_tarifa_base(noches) when noches <= 2, do: 120_000
  defp calc_tarifa_base(noches) when noches >= 3 and noches <= 5, do: 100_000
  defp calc_tarifa_base(noches) when noches > 5, do: 85000

  defp calcular_descuento(subtotal, :frecuente), do: subtotal * 0.20
  defp calcular_descuento(subtotal, :corporativo), do: subtotal * 0.15
  defp calcular_descuento(subtotal, :ocasional), do: subtotal * 0.0
  defp calcular_descuento(sub, _), do: sub * 0.0

  defp mostrar_mensaje({tarifa_base, subtotal, valor_descuento, valor_recargo, total}) do
    IO.puts("""
    Tarifa base por noche: $#{tarifa_base}
    Subtotal: $#{subtotal}
    Descuento: $#{valor_descuento}
    Recargo por temporada: $#{valor_recargo}
    Total a pagar: $#{total}
    """)
  end
end

Reservas.main()
