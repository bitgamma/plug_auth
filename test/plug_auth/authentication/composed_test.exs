defmodule PlugAuth.Authentication.Composed.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlugAuth.Authentication
  alias PlugAuth.CredentialStore

  @token_auth_error ~s'{"error":"authentication required"}'

  defmodule TestPlug do
    use Plug.Builder
    import Plug.Conn

    plug PlugAuth.Authentication.Basic,
      realm: "Secret",
      assign_key: :basic_user

    plug PlugAuth.Authentication.Token,
      source: :header,
      param: "x-auth-token",
      error: ~s'{"error":"authentication required"}',
      assign_key: :token_user
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  setup do
    CredentialStore.Agent.put_credentials("secret_token_composer", %{role: :token_admin})

    Authentication.Basic.encode_credentials("AdminComposer", "SecretPass")
    |> CredentialStore.Agent.put_credentials(%{role: :basic_admin})
  end

  test "request with valid credentials" do
    conn = call(TestPlug, auth_header("AdminComposer:SecretPass"), "secret_token_composer")
    assert_authorized conn, "Authorized"
  end

  test "request with invalid basic credentials" do
    conn = call(TestPlug, auth_header("Hacker:SecretPass"), "secret_token_composer")
    assert_basic_unauthorized conn, "Secret"
    refute conn.assigns[:token_user]
  end

  test "request with invalid token credentials" do
    conn = call(TestPlug, auth_header("AdminComposer:SecretPass"), "bad-token")
    assert conn.assigns[:basic_user] == %{role: :basic_admin}
    assert_token_unauthorized conn, @token_auth_error
  end

  defp call(plug, auth_header, token_header) do
    conn(:get, "/")
    |> put_req_header("authorization", auth_header)
    |> put_req_header("x-auth-token", token_header)
    |> plug.call([])
  end

  defp assert_basic_unauthorized(conn, realm) do
    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == [~s{Basic realm="#{realm}"}]
    refute conn.assigns[:basic_user]
  end

  defp assert_token_unauthorized(conn, content) do
    assert conn.status == 401
    assert conn.resp_body == content
    refute conn.assigns[:token_user]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:basic_user] == %{role: :basic_admin}
    assert conn.assigns[:token_user] == %{role: :token_admin}
  end

  defp auth_header(creds) do
    "Basic #{Base.encode64(creds)}"
  end

  defp auth_param(creds), do: {"auth_token", creds}
end
