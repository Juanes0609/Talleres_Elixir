Code.require_file("../problema-01/util.ex")

defmodule Aerolinea do
  @tarifa_bogota 80000
  @tarifa_medellin 90000
  @tarifa_cartagena 120_000
  @tarifa_san_andres 150_000

  @precio_silla 15000
  @precio_maleta 45000
  @precio_seguro 12000
  def main do
    input_destino =
      Util.ingresar(
        "Ingrese el destino de su vuelo (Bogota, Medellin, Cartagena o San Andres): ",
        :texto
      )

    destino = atomo_destino(String.trim(input_destino))

    case destino do
      :desconocido ->
        IO.puts("Destino no reconocido. Ingrese uno válido.")

      _ ->
        silla = Util.ingresar("¿Desea selección de silla? (s/n): ", :texto) |> String.trim("s")
        maleta = Util.ingresar("¿Desea maleta de bodega? (s/n): ", :texto) |> String.trim("s")
        seguro = Util.ingresar("¿Desea seguro de viaje? (s/n): ", :texto) |> String.trim("s")

        {total, maleta_auto} = calcular_total(destino, silla, maleta, seguro)

        IO.puts("\n-----Compra-----")
        IO.puts("Destino: #{destino}")

        if maleta_auto,
          do: IO.puts("Cargo de maleta agregada automáticamente (obligatoria para San Andrés).")

        IO.puts("Total a pagar: $#{total}")
    end
  end

  defp atomo_destino("Bogota"), do: :bogota
  defp atomo_destino("Medellin"), do: :medellin
  defp atomo_destino("Cartagena"), do: :cartagena
  defp atomo_destino("San Andres"), do: :san_andres
  defp atomo_destino(_), do: :desconocido

  defp calcular_total(destino, silla, maleta, seguro) do
    base = tarifa_base(destino)
    {costo_maleta, maleta_auto} = aplicar_maleta(destino, maleta)

    costo_silla = if silla, do: @precio_silla, else: 0
    costo_seguro = if seguro, do: @precio_seguro, else: 0

    total = base + costo_silla + costo_maleta + costo_seguro
    {total, maleta_auto}
  end

  defp tarifa_base(:bogota), do: @tarifa_bogota
  defp tarifa_base(:medellin), do: @tarifa_medellin
  defp tarifa_base(:cartagena), do: @tarifa_cartagena
  defp tarifa_base(:san_andres), do: @tarifa_san_andres

  defp aplicar_maleta(destino, _) when destino == :san_andres do
    {@precio_maleta, false}
  end

  defp aplicar_maleta(_, true), do: {@precio_maleta, false}
  defp aplicar_maleta(_, false), do: {0, false}
end

Aerolinea.main()
