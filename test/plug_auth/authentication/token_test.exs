defmodule PlugAuth.Authentication.Token.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  @error_msg ~s'{"error":"authentication required"}'

  defmodule ParamPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Authentication.Token, source: :params, param: "auth_token", error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defmodule HeaderPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Authentication.Token, source: :header, param: "X-Auth-Token", error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defp call(plug, params, headers) do
    conn(:get, "/", params, headers: headers)
    |> plug.call([])
  end

  defp assert_unauthorized(conn, content) do
    assert conn.status == 401
    assert conn.resp_body == content
    refute conn.assigns[:authenticated_user]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:authenticated_user] == %{role: :admin}
  end

  defp auth_header(creds), do: {"X-Auth-Token", creds}
  defp auth_param(creds), do: {"auth_token", creds}

  setup do
    PlugAuth.Authentication.Token.add_credentials("secret_token", %{role: :admin})
  end

  test "request without credentials using header-based auth" do
    conn = call(HeaderPlug, [], [])
    assert_unauthorized conn, @error_msg
  end

  test "request with invalid credentials using header-based auth" do
    conn = call(HeaderPlug, [], [auth_header("invalid_token")])
    assert_unauthorized conn, @error_msg
  end

  test "request with valid credentials using header-based auth" do
    conn = call(HeaderPlug, [], [auth_header("secret_token")])
    assert_authorized conn, "Authorized"
  end

  test "request without credentials using params-based auth" do
    conn = call(ParamPlug, [], [])
    assert_unauthorized conn, @error_msg
  end

  test "request with invalid credentials using params-based auth" do
    conn = call(ParamPlug, [auth_param("invalid_token")], [])
    assert_unauthorized conn, @error_msg
  end

  test "request with valid credentials using params-based auth" do
    conn = call(ParamPlug, [auth_param("secret_token")], [])
    assert_authorized conn, "Authorized"
  end
end