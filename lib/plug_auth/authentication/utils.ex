defmodule PlugAuth.Authentication.Utils do
  import Plug.Conn

  def assign_user_data(conn, user_data), do: assign(conn, :authenticated_user, user_data)
  def get_authenticated_user(conn), do: conn.assigns[:authenticated_user]
  def halt_with_error(conn, msg \\ "unauthorized") do
    conn 
    |> send_resp(401, msg) 
    |> halt
  end

  def get_first_req_header(conn, header), do: get_req_header(conn, header) |> header_hd
  
  defp header_hd([]), do: nil
  defp header_hd([head | _]), do: head
end