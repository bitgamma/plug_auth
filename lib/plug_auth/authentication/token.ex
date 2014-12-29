defmodule PlugAuth.Authentication.Token do
  @moduledoc """
    Implements token based authentication. To use add

    plug PlugAuth.Authentication.Token, source: :params, param: "auth_token"

    or

    plug PlugAuth.Authentication.Token, source: :session, param: "auth_token"

    or

    plug PlugAuth.Authentication.Token, source: :header, param: "X-Auth-Token"    

    or

    plug PlugAuth.Authentication.Token, source: fn conn -> { conn, my_very_special_retriever(conn)} end

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
    param = Keyword.get(opts, :param)
    source = Keyword.fetch!(opts, :source) |> convert_source(param)
    %{source: source}
  end

  defp convert_source(:params, param), do: quote do: fn conn -> {conn, conn.params[unquote(param)]} end
  defp convert_source(:header, param), do: quote do: fn conn -> {conn, get_first_req_header(conn, unquote(param))} end
  defp convert_source(:session, param), do: quote do: fn conn -> {conn, get_session(conn, unquote(param))} end
  defp convert_source(fun, _param), do: fun

  def call(conn, opts) do
    {fun, _} = Code.eval_quoted(opts[:source])

    conn
    |> fun.()
    |> verify_creds
    |> assert_creds
  end

  defp verify_creds({conn, creds}), do: {conn, PlugAuth.CredentialStore.get_user_data(creds)}

  defp assert_creds({conn, nil}), do: halt_with_error(conn, ~s'{"error":"authentication required"}')
  defp assert_creds({conn, user_data}), do: assign_user_data(conn, user_data)
end