Code.require_file("../problema-01/util.ex")

defmodule EntradaDatos do
  def main do
    "Ingresar el nombre del empleado: "
    |> Util.ingresar(:texto)
    |> generar_mensaje()
    |> Util.mostrar_mensaje()
  end

  defp generar_mensaje(nombre) do
    "Bienvenido #{nombre} a la empresa Once Ltda"
  end
end

EntradaDatos.main()
