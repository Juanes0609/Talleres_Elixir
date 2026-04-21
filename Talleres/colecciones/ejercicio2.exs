vuelos = [
  %{
    codigo: "AV201",
    aerolinea: "Avianca",
    origen: "BOG",
    destino: "MDE",
    duracion: 45,
    precio: 180_000,
    pasajeros: 120,
    disponible: true
  },
  %{
    codigo: "LA305",
    aerolinea: "Latam",
    origen: "BOG",
    destino: "CLO",
    duracion: 55,
    precio: 210_000,
    pasajeros: 98,
    disponible: true
  },
  %{
    codigo: "AV410",
    aerolinea: "Avianca",
    origen: "MDE",
    destino: "CTG",
    duracion: 75,
    precio: 320_000,
    pasajeros: 134,
    disponible: false
  },
  %{
    codigo: "VV102",
    aerolinea: "Viva Air",
    origen: "BOG",
    destino: "BAQ",
    duracion: 90,
    precio: 145_000,
    pasajeros: 180,
    disponible: true
  },
  %{
    codigo: "LA512",
    aerolinea: "Latam",
    origen: "CLO",
    destino: "CTG",
    duracion: 110,
    precio: 480_000,
    pasajeros: 76,
    disponible: false
  },
  %{
    codigo: "AV330",
    aerolinea: "Avianca",
    origen: "BOG",
    destino: "CTG",
    duracion: 135,
    precio: 520_000,
    pasajeros: 155,
    disponible: true
  },
  %{
    codigo: "VV215",
    aerolinea: "Viva Air",
    origen: "MDE",
    destino: "BOG",
    duracion: 50,
    precio: 130_000,
    pasajeros: 190,
    disponible: true
  },
  %{
    codigo: "LA620",
    aerolinea: "Latam",
    origen: "BOG",
    destino: "MDE",
    duracion: 145,
    precio: 390_000,
    pasajeros: 112,
    disponible: true
  },
  %{
    codigo: "AV505",
    aerolinea: "Avianca",
    origen: "CTG",
    destino: "BOG",
    duracion: 120,
    precio: 440_000,
    pasajeros: 143,
    disponible: false
  },
  %{
    codigo: "VV340",
    aerolinea: "Viva Air",
    origen: "BAQ",
    destino: "BOG",
    duracion: 85,
    precio: 160_000,
    pasajeros: 175,
    disponible: true
  }
]

vuelos_disponibles =
  vuelos
  |> Enum.filter(fn vuelo -> vuelo.disponible end)
  |> Enum.map(fn vuelo -> vuelo.codigo end)
  |> Enum.sort()

IO.inspect(vuelos_disponibles, label: "1. Vuelos Disponibles")


vuelos_avianca =
  vuelos
  |> Enum.filter(fn vuelo -> vuelo.aerolinea == "Avianca" end)
  |> Enum.reduce(0, fn vuelo, suma -> suma+vuelo.pasajeros end)

IO.puts("El nro de passengers de Avianca es: #{vuelos_avianca}")

vuelos_viva =
  vuelos
  |> Enum.filter(fn vuelo -> vuelo.aerolinea == "Viva Air" end)
  |> Enum.reduce(0, fn vuelo, suma -> suma+vuelo.pasajeros end)

IO.puts("El nro de passengers de Viva Air es: #{vuelos_viva}")

vuelos_formateados =
  vuelos
  |> Enum.map(fn vuelo ->
    horas = div(vuelo.duracion, 60)
    minutos = rem(vuelo.duracion, 60)

    # Agregamos el 0 si los minutos son menores a 10
    minutos_str = if minutos < 10, do: "0#{minutos}", else: to_string(minutos)

    "#{vuelo.codigo} — #{vuelo.origen} → #{vuelo.destino}: #{horas}h #{minutos_str}m"
  end)

IO.inspect(vuelos_formateados, label: "3. Vuelos formateados")

precio_limite = 400_000

vuelos_con_descuento =
  vuelos
  |> Enum.filter(fn vuelo -> vuelo.precio < precio_limite end)
  |> Enum.map(fn vuelo ->
    precio_final = vuelo.precio * 0.90
    {vuelo.codigo, "#{vuelo.origen}-#{vuelo.destino}", precio_final}
  end)
  # Ordenamos basándonos en el tercer elemento de la tupla (el precio_final)
  |> Enum.sort_by(fn {_codigo, _ruta, precio_final} -> precio_final end)

IO.inspect(vuelos_con_descuento, label: "4. Vuelos con descuento")

aerolineas_variadas =
  vuelos
  |> Enum.group_by(fn vuelo -> vuelo.aerolinea end)
  |> Enum.filter(fn {_aerolinea, vuelos_aerolinea} ->
    # Mapeamos los vuelos de esta aerolínea a sus categorías de duración
    categorias =
      Enum.map(vuelos_aerolinea, fn v ->
        cond do
          v.duracion < 60 -> :corto
          v.duracion >= 60 and v.duracion <= 120 -> :medio
          v.duracion > 120 -> :largo
        end
      end)

    # Verificamos que la aerolínea tenga al menos un vuelo en cada categoría
    Enum.member?(categorias, :corto) and
    Enum.member?(categorias, :medio) and
    Enum.member?(categorias, :largo)
  end)
  # Como group_by devuelve tuplas {aerolinea, vuelos}, extraemos solo el nombre
  |> Enum.map(fn {aerolinea, _vuelos} -> aerolinea end)

IO.inspect(aerolineas_variadas, label: "5. Aerolíneas con todas las categorías")

rutas_rentables =
  vuelos
  |> Enum.filter(fn vuelo -> vuelo.disponible end)
  |> Enum.map(fn vuelo ->
    {"#{vuelo.origen} → #{vuelo.destino}", vuelo.precio * vuelo.pasajeros}
  end)
  |> Enum.sort_by(fn {_ruta, ingreso} -> ingreso end, :desc)
  |> Enum.take(3)

IO.inspect(rutas_rentables, label: "6. Top 3 rutas rentables")
