defmodule PlugAuth.Authentication.Utils do
  import Plug.Conn

  def assign_user_data(conn, user_data, key \\ :authenticated_user) do
    assign(conn, key, user_data)
  end

  def get_authenticated_user(conn, key \\ :authenticated_user) do
    conn.assigns[key]
  end

  def halt_with_error(conn, error \\ "unauthorized")
  def halt_with_error(conn, error) when is_function(error) do
    error.(conn)
    |> halt
  end
  def halt_with_error(conn, error) do
    conn
    |> send_resp(401, error)
    |> halt
  end

  def get_first_req_header(conn, header), do: get_req_header(conn, header) |> header_hd

  defp header_hd([]), do: nil
  defp header_hd([head | _]), do: head
end
