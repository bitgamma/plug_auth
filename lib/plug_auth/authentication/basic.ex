defmodule PlugAuth.Authentication.Basic do
  @moduledoc """
    Implements basic HTTP authentication. To use add:

      plug PlugAuth.Authentication.Basic, realm: "Secret world"

    to your pipeline. This module is derived from https://github.com/lexmag/blaguth
  """

  @behaviour Plug
  import Plug.Conn
  import PlugAuth.Authentication.Utils

  @doc """
    Returns the encoded form for the given `user` and `password` combination.
  """
  def encode_credentials(user, password), do: Base.encode64("#{user}:#{password}")

  def init(opts) do
    realm = Keyword.get(opts, :realm, "Restricted Area")
    error = Keyword.get(opts, :error, "HTTP Authentication Required")
    store = Keyword.get(opts, :store, PlugAuth.CredentialStore.Agent)
    assign_key = Keyword.get(opts, :assign_key, :authenticated_user)
    %{realm: realm, error: error, store: store, assign_key: assign_key}
  end

  def call(conn, opts) do
    if get_authenticated_user(conn, opts[:assign_key]) do
      conn
    else
      conn
      |> get_auth_header
      |> verify_creds(opts[:store])
      |> assert_creds(opts[:realm], opts[:error], opts[:assign_key])
    end
  end

  defp get_auth_header(conn), do: {conn, get_first_req_header(conn, "authorization")}

  defp verify_creds({conn, << "Basic ", creds::binary >>}, store), do: {conn, store.get_user_data(creds)}
  defp verify_creds({conn, _}, _), do: {conn, nil}

  defp assert_creds({conn, nil}, realm, error, _), do: halt_with_login(conn, realm, error)
  defp assert_creds({conn, user_data}, _, _, key), do: assign_user_data(conn, user_data, key)

  defp halt_with_login(conn, realm, error) do
    conn
    |> put_resp_header("www-authenticate", ~s{Basic realm="#{realm}"})
    |> halt_with_error(error)
  end
end
