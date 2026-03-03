Code.require_file("../problema-01/util.ex")

defmodule ValidarCupon do
  def main do
    cupon = Util.ingresar("Ingrese el cupón: ", :texto)
    resultado = validar(cupon)
    case resultado do
     {:ok, msj} -> IO.puts("#{msj}")
     {:error, msj} -> IO.puts("Error: #{msj}")

    end
  end

  def validar(cupon) do
    []
    |> validar_longitud(cupon)
    |> validar_mayuscula(cupon)
    |> validar_numero(cupon)
    |> validar_espacios(cupon)
    |> generar_resultado()
  end

  defp validar_longitud(errores, cupon) do
    if String.length(cupon) < 10 do
      errores ++ ["debe tener al menos 10 caracteres"]
    else
      errores
    end
  end

  defp validar_mayuscula(errores, cupon) do
    if String.downcase(cupon) == cupon do
      errores ++ ["debe contener al menos una letra mayúscula"]
    else
      errores
    end
  end

  defp validar_numero(errores, cupon) do
    tiene_numero = Enum.any?(0..9, fn n -> String.contains?(cupon, Integer.to_string(n)) end)

    if not tiene_numero do
      errores ++ ["debe contener al menos un número"]
    else
      errores
    end
  end

  defp validar_espacios(errores, cupon) do
    if String.contains?(cupon, " ") do
      errores ++ ["no debe contener espacios en blanco"]
    else
      errores
    end
  end

  defp generar_resultado([]) do
    {:ok, "Cupón válido"}
  end

  defp generar_resultado(lista_errores) do
    mensaje = "El cupón " <> Enum.join(lista_errores, " y ")
    {:error, mensaje}
  end
end

ValidarCupon.main()
