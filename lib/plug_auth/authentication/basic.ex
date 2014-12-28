defmodule PlugAuth.Authentication.Basic do
  @behaviour Plug
  import Plug.Conn
  import PlugAuth.Authentication.Utils

  def add_credentials(user, password, user_data \\ []) do
    encode_creds(user, password) |> PlugAuth.CredentialStore.put_credentials(user_data)
  end

  defp encode_creds(user, password), do: Base.encode64("#{user}:#{password}")

  def init(opts) do
    {realm, _opts} = Keyword.pop(opts, :realm, "Restricted Area")
    %{realm: realm}
  end

  def call(conn, opts) do
    conn
    |> get_auth_header
    |> decode_creds
    |> assert_creds(opts[:realm])
  end

  defp get_auth_header(conn), do: {conn, get_req_header(conn, "authorization")}

  defp decode_creds({conn, ["Basic " <> encoded_creds | _]}), do: {conn, PlugAuth.CredentialStore.get_user_data(encoded_creds)}
  defp decode_creds({conn, _}), do: {conn, nil}

  defp assert_creds({conn, nil}, realm), do: halt_with_login(conn, realm)
  defp assert_creds({conn, user_data}, _), do: assign_user_data(conn, user_data)

  def halt_with_login(conn, realm) do
    conn 
    |> put_resp_header("Www-Authenticate", ~s[Basic realm="#{realm}"])
    |> halt_with_error("HTTP Basic: Access denied.\n")
  end
end