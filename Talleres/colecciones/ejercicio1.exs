def procesar(lista) do
  lista
  # Transforma los elementos de la lista a mayúsculas
  |> Enum.map(&(String.upcase(&1)))

  # Filtra cada cadena mayor a 4 caracteres
  |> Enum.filter(fn w -> String.length(w) > 4 end)

  # Transforma las cadenas y las invierte "ELIXIR" a "RIXILE"
  |> Enum.map(fn cadena -> String.reverse(cadena) end)

  # Ordena cada cadena de la lista por orden alfabético
  |> Enum.sort()

  #Toma los primeros 3 elementos de la lista
  |> Enum.take(3)

  # Une los elementos de la lista en una sola cadena de texto, separándolos por " - "
  |> Enum.join(" - ")
end

IO.puts( procesar(["Elixir", "es", "un", "lenguaje", "funcional", "muy", "poderoso"]) )
# imprime: "LANOICNUF - OSOREDOP - RIXILE"


numeros = Enum.to_list(1..15)

resultado =
  numeros
  #filtra los multiplos de 3: 3, 6, 9, 12, 15
  |> Enum.filter(&(rem(&1, 3) == 0))

  # suma 1 a cada elemento de la lista: 4, 7, 10, 13, 16
  |> Enum.map(&(&1 + 1))
  #Inicializa una tupla y la recorre aplicando la condicion de fn, retorna la tupla con el resultado: {4 + 7 + 10 + 13 + 16, 4}
  |> Enum.reduce({0, 0}, fn x, {suma, conteo} -> {suma + x, conteo + 1} end)
  # toma la tupla anterior '{40, 4}' y la suma entre el conteo, para sacar el promedio: {10}
  |> then(fn {suma, conteo} -> suma / conteo end)

IO.puts("Salida: #{resultado}")
# imprime: Salida: 10

personas = [
  %{nombre: "Antonio", edad: 23},
  %{nombre: "Luis", edad: 30},
  %{nombre: "Marta", edad: 19},
  %{nombre: "Pedro", edad: 40},
  %{nombre: "Andrés", edad: 28},
  %{nombre: "Ana", edad: 35}
]

resultado =
  personas
  # Filtra las personas que tienen 21 años o más y cuyo nombre empieza con la letra "a"
  |> Enum.filter(fn %{nombre: nombre, edad: edad} ->
    edad >= 21 and (nombre |> String.downcase() |> String.starts_with?("a"))
  end)

  # Transforma la lista de mapas extrayendo solo el nombre y convirtiéndolo a mayúsculas
  |> Enum.map(fn %{nombre: nombre} -> String.upcase(nombre) end)

  # Ordena los nombres resultantes de menor a mayor según la cantidad de letras (longitud)
  |> Enum.sort_by(&String.length(&1))

  # Une todos los nombres en una sola cadena de texto, separándolos por " | "
  |> Enum.join(" | ")

IO.puts(resultado)
# imprime: ANA | ANDRÉS | ANTONIO



