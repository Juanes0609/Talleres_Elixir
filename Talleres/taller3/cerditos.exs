defmodule Carrera do
  @pos_meta 50
  @intervalo_min 100
  @intervalo_max 500

  def main do
    principal = self()
    cerditos = ["Cerdito1", "Cerdito2", "Cerdito3", "Cerdito4"]

    tareas =
      Enum.map(cerditos, fn nombre ->
        {:ok, pid} = Task.start(fn -> correr(nombre, 0, principal) end)
        pid
      end)

    esperar_ganador(tareas)
  end

  defp correr(nombre, posicion, principal) do
    :timer.sleep(Enum.random(@intervalo_min..@intervalo_max))

    nueva_pos = min(posicion + Enum.random(1..3), @pos_meta)

    send(principal, {:avance, nombre, nueva_pos})

    if nueva_pos < @pos_meta, do: correr(nombre, nueva_pos, principal)
  end

  defp esperar_ganador(tareas) do
    receive do
      {:avance, nombre, pos} ->
        barra = String.duplicate("x", div(pos, 2))
        IO.puts("#{nombre}: [#{barra}] #{pos}/#{@pos_meta}")

        if pos >= @pos_meta do
          IO.puts("¡#{nombre} ganó la carrera!")

          Enum.each(tareas, fn tarea -> Process.exit(tarea, :kill) end)
        else
          esperar_ganador(tareas)

        end
    end
  end
end

Carrera.main()


@doc "Opción 2"

@moduledoc """

Code.require_file("Cerdito.exs")

defmodule Ejercicio2.Carrera do
  @distancia_carrera 25

  def main() do
    cerdo1 = %Ejercicio2.Cerdito{nombre: "cerdo1", recorrido: 0}
    cerdo2 = %Ejercicio2.Cerdito{nombre: "cerdo2", recorrido: 0}
    cerdo3 = %Ejercicio2.Cerdito{nombre: "cerdo3", recorrido: 0}
    cerdo4 = %Ejercicio2.Cerdito{nombre: "cerdo4", recorrido: 0}

    cerditos = [cerdo1, cerdo2, cerdo3, cerdo4]

    simulacion(cerditos, @distancia_carrera)
  end

  defp simulacion(cerditos, _distancia_carrera) do
    proceso = Enum.map(cerditos, fn cerdo ->
      Task.async(fn -> avance_simulado(cerdo, 0) end)
    end)

    Enum.each(proceso, &Task.await(&1, :infinity))
  end

  defp avance_simulado(cerdo, recorrido) when recorrido >= 25 do
    IO.puts("#{cerdo.nombre} ha ganado")
    Process.exit(proceso, :kill)
  end

  defp avance_simulado(cerdo, recorrido) do
    :timer.sleep(500)

    paso = Enum.random(1..3)

    IO.puts("#{cerdo.nombre} ha avanzado #{paso} pasos")
    nuevo_progreso = recorrido + paso

    avance_simulado(cerdo, nuevo_progreso)
  end

end

Ejercicio2.Carrera.main()
"""
