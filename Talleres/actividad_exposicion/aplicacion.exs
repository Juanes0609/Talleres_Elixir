Code.require_file("../problema-01/util.ex")

defmodule App do
  @moduledoc """
  Juego por consola con CRUD aplicando listas, tuplas y mapas.
  """
  def contratar_empleado(empresa) do
    nombre = Util.ingresar("Nombre del empleado: ", :texto)
    cargo = Util.ingresar("Cargo (ej. Desarrollador, Analista, Ventas): ", :texto)

    # Mapa para representar el empleado
    nuevo_empleado = %{
      id: empresa.nuevo_id,
      nombre: nombre,
      cargo: cargo,
      habilidades: []
    }

    nuevos_empleados = [nuevo_empleado | empresa.empleados]

    nuevo_estado = {:ok, "Empleado #{nombre} contratado exitosamente"}

    # Se actualiza el mapa de la empresa
    %{
      empresa
      | empleados: nuevos_empleados,
        proximo_id: empresa.nuevo_id + 1,
        estado: nuevo_estado
    }
  end

  def listar_empleados(empresa) do
    Util.mostrar_mensaje("\n---Nómina de Empleados---")

    if empresa.empleados == [] do
      Util.mostrar_mensaje("La empresa aún no tiene empleados registrados.")
    else
      # Enum.each para recorrer la lista de mapas
      Enum.each(empresa.empleados, fn emp ->
        Util.mostrar_mensaje("[ID: #{emp.id}] | Cargo: #{emp.cargo}")

        if length(emp.habilidades) > 0 do
          # Se muestra la lista de habilidades si no está vacia
          Util.mostrar_mensaje(" | Habilidades: #{Enum.join(emp.habilidades, ", ")}")
        end
      end)
    end

    # Pattern matching para extraer el estado
    {status, mensaje} = empresa.estado
    Util.mostrar_mensaje("\n>> Estado actual: #{mensaje} (#{status})")

    empresa
  end

  def capacitar_empleado(empresa) do
    id_str = Util.ingresar("Ingrese el ID del empleado para capacitar: ", :entero)

    # Verificando si existe usando Enum.any?
    empleado_existe = Enum.any?(empresa.empleados, fn e -> e.id == id_str end)

    if empleado_existe do
      nueva_hab = Util.ingresar("Nueva habilidad (ej. Elixir, Python, Java): ", :texto)

      # Se transforma la lista con Enum.map/2 aplicando las instrucciones de la funcion anonima
      empleados_actualizados =
        Enum.map(empresa.empleados, fn emp ->
          if emp.id == id_str do
            # Se inserta la nueva habilidad a la cabeza de la lista
            %{emp | habilidades: [nueva_hab | emp.habilidades]}
          else
            emp
          end
        end)

      %{
        empresa
        | empleados: empleados_actualizados,
          estado: {:ok, "Empleado ID #{id_str} capacitado con éxito"}
      }
    else
      Util.mostrar_error("No se encontró ningún empleado con ese ID.")
      %{empresa | estado: {:error, "Intento fallido de capacitación"}}
    end
  end

  def despedir_empleado(empresa) do
    id_str = Util.ingresar("Ingrese el ID del empleado a dar de baja: ", :entero)

    # Se filtra la lista conservando los que no coinciden con id_str
    empleados_restantes = Enum.filter(empresa.empleados, fn emp -> emp.id != id_str end)

    # Si no se modifico el tamaño de la lista, significa que no existe id_str en empresa.empleados
    if length(empleados_restantes) == length(empresa.empleados) do
      Util.mostrar_mensaje("No se encontró el empleado.")
      %{empresa | estado: {:error, "ID no válido para despedir"}}
    else
      Util.mostrar_mensaje("Empleado dado de baja del sistema.")
      %{empresa | estado: {:ok, "Empleado eliminado del sistema"}}
    end
  end

  def main do
    # Estado inicial almacenado en un mapa
    estado_inicial = %{
      nombre: "ScaleLabs",
      empleados: [],
      proximo_id: 1,
      estado: {:ok, "Sistema de Recursos Humanos iniciado"}
    }

    Util.mostrar_mensaje("---------------------------------------------")
    Util.mostrar_mensaje("BIENVENIDO A #{String.upcase(estado_inicial.nombre)}")
    Util.mostrar_mensaje("---------------------------------------------")

    loop(estado_inicial)
  end

  # Al no haber while o for usamos recursión funcional
  defp loop(empresa) do
    Util.mostrar_mensaje("""
    \nMenú principal
    1. Contratar empleado
    2. Ver nómina
    3. Capacitar empleado
    4. Dar de baja a un empleado
    5. Salir
    """)

    opcion = Util.ingresar("Elige una opción (1-5): ", :entero)

    datos_empresa =
      case opcion do
        1 -> contratar_empleado(empresa)
        2 -> listar_empleados(empresa)
        3 -> capacitar_empleado(empresa)
        4 -> despedir_empleado(empresa)
        5 -> :salir
         _ -> Util.mostrar_error("Opción inválida")

        empresa
      end

    if datos_empresa == :salir do
      Util.mostrar_mensaje("¡Apagando sistema!")
    else
      loop(datos_empresa)
    end
  end
end

App.main()
