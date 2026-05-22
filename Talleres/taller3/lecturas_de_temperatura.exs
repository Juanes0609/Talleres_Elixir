defmodule SensorLectura do
  defstruct id: nil, zona: "", temperaturas: []
end

defmodule CalculoTemperatura do
  alias SensorLectura

  def procesar_sensor(%SensorLectura{temperaturas: temps}) when temps != [] do
    promedio = Enum.sum(temps) / Enum.count(temps)
    {:ok, promedio}
  end

  def procesar_sensor(%SensorLectura{temperaturas: []}) do
  {:ok, 0.0}
  end

  def main do
    lecturas = [
      %SensorLectura{id: 1, zona: "Zona A", temperaturas: [22.5, 23.0, 24.5]},
      %SensorLectura{id: 2, zona: "Zona B", temperaturas: [18.0, 19.2, 17.5]},
      %SensorLectura{id: 3, zona: "Zona C", temperaturas: [30.1, 29.8, 31.0]}
    ]

    lecturas
    |> Task.async_stream(fn lectura -> procesar_sensor(lectura) end)
    |> Enum.map(fn {:ok, promedio} -> promedio end)
    |> IO.inspect(label: "Resultados concurrentes")

  end
end
