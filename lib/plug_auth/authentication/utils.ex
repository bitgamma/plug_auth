defmodule PlugAuth.Authentication.Utils do
  import Plug.Conn

  def assign_user_data(conn, user_data, key \\ :authenticated_user) do
    assign(conn, key, user_data)
  end

  def get_authenticated_user(conn, key \\ :authenticated_user) do
    conn.assigns[key]
  end

  def halt_with_error(conn, msg \\ "unauthorized") do
    conn 
    |> send_resp(401, msg) 
    |> halt
  end

  def get_first_req_header(conn, header), do: get_req_header(conn, header) |> header_hd
  
  defp header_hd([]), do: nil
  defp header_hd([head | _]), do: head
end
