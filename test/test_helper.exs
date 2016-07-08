defmodule PlugAuth.TestHelpers do
  import Plug.Conn

  def handler(conn) do
    conn
    |> assign(:error_handler_called, true)
    |> send_resp(418, "I'm a teapot")
  end
end

ExUnit.start()
