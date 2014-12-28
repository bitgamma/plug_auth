defmodule PlugAuth.Authentication.Basic.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule TestPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Authentication.Basic, realm: "Secret"
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defp call(plug, headers) do
    conn(:get, "/", [], headers: headers)
    |> plug.call([])
  end

  defp assert_unauthorized(conn, realm) do
    assert conn.status == 401
    assert get_resp_header(conn, "Www-Authenticate") == [~s{Basic realm="#{realm}"}]
    refute conn.assigns[:authenticated_user]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:authenticated_user] == %{role: :admin}
  end

  defp auth_header(creds) do
    {"authorization", "Basic #{Base.encode64(creds)}"}
  end

  setup do
    PlugAuth.Authentication.Basic.add_credentials("Admin", "SecretPass", %{role: :admin})
  end

  test "request without credentials" do
    conn = call(TestPlug, [])
    assert_unauthorized conn, "Secret"
  end

  test "request with invalid user" do
    conn = call(TestPlug, [auth_header("Hacker:SecretPass")])
    assert_unauthorized conn, "Secret"
  end

  test "request with invalid password" do
    conn = call(TestPlug, [auth_header("Admin:ASecretPass")])
    assert_unauthorized conn, "Secret"
  end

  test "request with valid credentials" do
    conn = call(TestPlug, [auth_header("Admin:SecretPass")])
    assert_authorized conn, "Authorized"
  end

  test "request with malformed credentials" do
    conn = call(TestPlug, [{"authorization", "Basic Zm9)"}])
    assert_unauthorized conn, "Secret"
  end

  test "request with wrong scheme" do
    conn = call(TestPlug, [{"authorization", "Bearer #{Base.encode64("Admin:SecretPass")}"}])
    assert_unauthorized conn, "Secret"
  end
end