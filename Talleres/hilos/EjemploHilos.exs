defmodule EjemploHilos do
  def saludar(nombre) do
    Process.sleep(1000)
    IO.puts("¡Hola! Soy el proceso de #{nombre}")
  end

  def iniciar do
    IO.puts("Iniciando el programa principal...")

    pid1 = spawn(fn -> saludar("Alice") end)
    pid2 = spawn(fn -> saludar("Bob") end)
    pid3 = spawn(fn -> saludar("Charlie") end)

    IO.puts("Procesos creados con PIDs: #{inspect(pid1)}, #{inspect(pid2)}, #{inspect(pid3)}")

    IO.puts(
      "El programa principal terminó de dar las órdenes, pero los procesos siguen trabajando en el fondo..."
    )
  end
end

EjemploHilos.iniciar()
