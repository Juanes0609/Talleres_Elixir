# Creacion de mapa vacíos
mapa_vacio = %{}

# Mapa con objetos

persona = %{
  "nombre" => "Juan",
  "apellido" => "Chica",
  "correo" => "juanc@email.com"
}

usuario = %{
  nombre: "María",
  correo: "maria@emai.com",
  edad: 30
}

# acceder a valores con atomos

usuario([:nombre])
usuario.nombre
persona["edad"]


#------------------------------------
producto = %{nombre: "Laptop", precio: 1500, stock: 10}

# Obtener valor con default
Map.get(producto, :descuento, 0)

# Verificar si existe una clave
Map.has_key?(producto, :precio)
Map.has_key?(producto, :color)

# Eliminar clave
Map.delete(producto, :stock)

# Obtener solo las claves
Map.keys(producto)

# Obtener solo los valores
Map.values(producto)

# Merge (combinar mapas)
config_default = %{host: "localhost", port: 8080}
config_user = %{port: 3000, debug: true}
Map.merge(config_default, config_user)
# %{host: "localhost", port: 3000, debug: true}


#------------------------------------
precios = %{manzana: 1.5, banana: 0.8, naranja: 1.2}

# Enum.map
Enum.map(precios, fn {fruta, precio} -> {fruta, precio * 1.1} end)

# Enum.filter
Enum.filter(precios, fn {_fruta, precio} -> precio > 1.0 end)

# Enum.reduce
Enum.reduce(precios, 0, fn {_fruta, precio}, acc -> acc + precio end)

# For comprehension
for {fruta, precio} <- precios, precio > 1.0 do
  "#{fruta}: $#{precio}"
end


#------------------------------------
# Extraer valores específicos
%{nombre: n, edad: e} = %{nombre: "Ana", edad: 22, ciudad: "Cali"}

# Verificar estructura en funciones
defmodule Usuario do
  def saludar(%{nombre: nombre, edad: edad}) do
    "Hola #{nombre}, tienes #{edad} años"
  end

  def es_adulto?(%{edad: edad}) when edad >= 18, do: true
  def es_adulto?(_), do: false
end

Usuario.saludar(%{nombre: "Luis", edad: 25})
Usuario.es_adulto?(%{nombre: "Pedro", edad: 20})


#------------------------------------
# Ejemplo
defmodule Carrito do
  def nuevo(), do: %{}

  def agregar_producto(carrito, producto, cantidad \\ 1) do
    Map.update(carrito, producto, cantidad, &(&1 + cantidad))
  end

  def remover_producto(carrito, producto) do
    Map.delete(carrito, producto)
  end

  def total_items(carrito) do
    Enum.reduce(carrito, 0, fn {_prod, cant}, acc -> acc + cant end)
  end

  def listar(carrito) do
    Enum.map(carrito, fn {prod, cant} ->
      "#{prod}: #{cant} unidad(es)"
    end)
  end
end

# Uso
carrito =
  Carrito.nuevo()
  |> Carrito.agregar_producto("Laptop", 1)
  |> Carrito.agregar_producto("Mouse", 2)
  |> Carrito.agregar_producto("Teclado", 1)

Carrito.total_items(carrito)
Carrito.listar(carrito)
