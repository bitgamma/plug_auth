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

  defmodule BasicErrorHandlerPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Authentication.Basic, realm: "Secret", error: &PlugAuth.TestHelpers.handler/1
  end

  defp call(plug, headers) do
    conn(:get, "/", [])
    |> put_req_header("authorization", headers)
    |> plug.call([])
  end

  defp assert_unauthorized(conn, realm) do
    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == [~s{Basic realm="#{realm}"}]
    refute conn.assigns[:authenticated_user]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:authenticated_user] == %{role: :admin}
  end

  defp assert_error_handler_called(conn) do
    assert conn.status == 418
    assert conn.resp_body == "I'm a teapot"
    assert conn.assigns[:error_handler_called]
  end

  defp auth_header(creds) do
    "Basic #{Base.encode64(creds)}"
  end

  setup do
    PlugAuth.Authentication.Basic.encode_credentials("Admin", "SecretPass")
    |> PlugAuth.CredentialStore.Agent.put_credentials(%{role: :admin})
  end

  test "request without credentials" do
    connection = conn(:get, "/", []) |> TestPlug.call([])
    assert_unauthorized connection, "Secret"
  end

  test "request with invalid user" do
    conn = call(TestPlug, auth_header("Hacker:SecretPass"))
    assert_unauthorized conn, "Secret"
  end

  test "request with invalid password" do
    conn = call(TestPlug, auth_header("Admin:ASecretPass"))
    assert_unauthorized conn, "Secret"
  end

  test "request with valid credentials" do
    conn = call(TestPlug, auth_header("Admin:SecretPass"))
    assert_authorized conn, "Authorized"
  end

  test "request with malformed credentials" do
    conn = call(TestPlug, "Basic Zm9)")
    assert_unauthorized conn, "Secret"
  end

  test "request with wrong scheme" do
    conn = call(TestPlug, "Bearer #{Base.encode64("Admin:SecretPass")}")
    assert_unauthorized conn, "Secret"
  end

  test "request without credentials using error handler" do
    conn(:get, "/", [])
    |> BasicErrorHandlerPlug.call([])
    |> assert_error_handler_called
  end

  test "request with invalid user using error handler" do
    call(BasicErrorHandlerPlug, auth_header("Hacker:SecretPass"))
    |> assert_error_handler_called
  end

  test "request with invalid password using error handler" do
    call(BasicErrorHandlerPlug, auth_header("Admin:ASecretPass"))
    |> assert_error_handler_called
  end

  test "request with malformed credentials using error handler" do
    call(BasicErrorHandlerPlug, "Basic Zm9)")
    |> assert_error_handler_called
  end

  test "request with wrong scheme using error handler" do
    call(BasicErrorHandlerPlug, "Bearer #{Base.encode64("Admin:SecretPass")}")
    |> assert_error_handler_called
  end
end
