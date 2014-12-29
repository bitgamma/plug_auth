defmodule PlugAuth.Authentication.Token do
  @moduledoc """
    Implements basic HTTP authentication. To use add

    plug PlugAuth.Authentication.Token, source: :params, param: "auth_token"

    to your pipeline.
  """ 

  @behaviour Plug
  import Plug.Conn
  import PlugAuth.Authentication.Utils

  @doc """
    Add the credentials for a `token`. `user_data` can be any term but must not be `nil`.
  """
  def add_credentials(token, user_data) do
    PlugAuth.CredentialStore.put_credentials(token, user_data)
  end

  @doc """
    Remove the credentials for a `token`.
  """
  def remove_credentials(token) do
    PlugAuth.CredentialStore.delete_credentials(token)
  end

  def init(opts) do
    source = Keyword.fetch!(opts, :source) |> convert_source
    param = Keyword.fetch!(opts, :param)
    %{source: source, param: param}
  end

  defp convert_source(:params), do: fn conn, param -> {conn, conn.params[param]} end
  defp convert_source(:header), do: fn conn, param -> {conn, get_first_req_header(conn, param)} end
  defp convert_source(:session), do: fn conn, param -> {conn, get_session(conn, param)} end
  defp convert_source(fun) when is_function(fun, 2), do: fun

  def call(conn, opts) do
    conn
    |> opts[:source].(opts[:param])
    |> verify_creds
    |> assert_creds
  end

  defp verify_creds({conn, creds}), do: {conn, PlugAuth.CredentialStore.get_user_data(creds)}

  defp assert_creds({conn, nil}), do: halt_with_error(conn, ~s'{"error":"authentication required"}')
  defp assert_creds({conn, user_data}), do: assign_user_data(conn, user_data)
end