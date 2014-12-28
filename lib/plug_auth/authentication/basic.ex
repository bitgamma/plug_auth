defmodule PlugAuth.Authentication.Basic do
  @moduledoc """
    Implements basic HTTP authentication. To use add

    plug PlugAuth.Authentication.Basic, realm: "Secret world"

    to your pipeline. This module is derived from https://github.com/lexmag/blaguth
  """ 

  @behaviour Plug
  import Plug.Conn
  import PlugAuth.Authentication.Utils

  @doc """
    Add the credentials for a `user` and `password` combination. `user_data` can be any term but must not be `nil`.
  """
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

  defp decode_creds({conn, ["Basic " <> creds | _]}), do: {conn, PlugAuth.CredentialStore.get_user_data(creds)}
  defp decode_creds({conn, _}), do: {conn, nil}

  defp assert_creds({conn, nil}, realm), do: halt_with_login(conn, realm)
  defp assert_creds({conn, user_data}, _), do: assign_user_data(conn, user_data)

  defp halt_with_login(conn, realm) do
    conn 
    |> put_resp_header("Www-Authenticate", ~s{Basic realm="#{realm}"})
    |> halt_with_error("HTTP Basic: Access denied.\n")
  end
end