defmodule PlugAuth.Authentication.Utils do
  import Plug.Conn

  def assign_user_data(conn, user_data), do: assign(conn, :authenticated_user, user_data)
  def halt_with_error(conn, msg \\ "unauthorized") do
    conn 
    |> send_resp(401, msg) 
    |> halt
  end
end