# IO.puts("Bienvenido a la empresa Once Ltda")


# "Bienvenidos a la empresa Once Ltda"
# |>IO.puts()



# defmodule Mensaje do
#   def main do
#     "Bienvenidos a la empresa Once Ltda"
#     |> mostrar_mensaje()
#   end
#   defp mostrar_mensaje(mensaje) do
#     mensaje
#     |> IO.puts()
#   end
# end
# Mensaje.main()


defmodule Mensaje do
  def main do
    "Bienvenidos a la empresa Once Ltda"
    |> Util.mostrar_mensaje()

  end
end

Mensaje.main()
