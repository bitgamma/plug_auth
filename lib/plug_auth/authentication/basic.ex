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
    Add the credentials for a `user` and `password` combination. `user_data` can be any term but must not be `nil`.
  """
  def add_credentials(user, password, user_data) do
    encode_creds(user, password) |> PlugAuth.CredentialStore.put_credentials(user_data)
  end

  @doc """
    Remove the credentials for a `user` and `password` combination.
  """
  def remove_credentials(user, password) do
    encode_creds(user, password) |> PlugAuth.CredentialStore.delete_credentials
  end

  @doc """
    Changes the password for `user` from `old_password` to `new_password`.
  """
  def update_credentials(user, old_password, new_password) do
    user_data = remove_credentials(user, old_password)
    add_credentials(user, new_password, user_data)
  end

  defp encode_creds(user, password), do: Base.encode64("#{user}:#{password}")

  def init(opts) do
    realm = Keyword.get(opts, :realm, "Restricted Area")
    error = Keyword.get(opts, :error, "HTTP Authentication Required")
    %{realm: realm, error: error}
  end

  def call(conn, opts) do
    conn
    |> get_auth_header
    |> verify_creds
    |> assert_creds(opts[:realm], opts[:error])
  end

  defp get_auth_header(conn), do: {conn, get_first_req_header(conn, "authorization")}

  defp verify_creds({conn, << "Basic ", creds::binary >>}), do: {conn, PlugAuth.CredentialStore.get_user_data(creds)}
  defp verify_creds({conn, _}), do: {conn, nil}

  defp assert_creds({conn, nil}, realm, error), do: halt_with_login(conn, realm, error)
  defp assert_creds({conn, user_data}, _, _), do: assign_user_data(conn, user_data)

  defp halt_with_login(conn, realm, error) do
    conn 
    |> put_resp_header("Www-Authenticate", ~s{Basic realm="#{realm}"})
    |> halt_with_error(error)
  end
end