defmodule PlugAuth.Access.Role.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule TestPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Access.Role, roles: [:admin], error: "forbidden"
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defp call(plug, role) do
    conn(:get, "/", [])
    |> assign(:authenticated_user, %{role: role})
    |> plug.call([])
  end

  defp assert_unauthorized(conn, content) do
    assert conn.status == 403
    assert conn.resp_body == content
    refute conn.assigns[:authenticated_role]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:authenticated_role] == :admin
  end

  test "request with no role" do
    conn = call(TestPlug, nil)
    assert_unauthorized conn, "forbidden"
  end

  test "request with invalid role" do
    conn = call(TestPlug, :guest)
    assert_unauthorized conn, "forbidden"
  end

  test "request with valid credentials" do
    conn = call(TestPlug, :admin)
    assert_authorized conn, "Authorized"
  end
end