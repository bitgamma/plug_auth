defmodule PlugAuth.Authentication.Token do
  @moduledoc """
    Implements token based authentication. To use add

      plug PlugAuth.Authentication.Token, source: :params, param: "auth_token"

    or

      plug PlugAuth.Authentication.Token, source: :session, param: "auth_token"

    or

      plug PlugAuth.Authentication.Token, source: :header, param: "X-Auth-Token"

    or

      plug PlugAuth.Authentication.Token, source: { module, function, ["my_param"]} end

    to your pipeline.
  """

  @behaviour Plug
  import Plug.Conn
  import PlugAuth.Authentication.Utils

  @doc """
    Utility function to generate a random authentication token.
  """
  def generate_token() do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64
  end

  def init(opts) do
    param = Keyword.get(opts, :param)
    source = Keyword.fetch!(opts, :source) |> convert_source(param)
    error = Keyword.get(opts, :error, "HTTP Authentication Required")
    store = Keyword.get(opts, :store, PlugAuth.CredentialStore.Agent)
    assign_key = Keyword.get(opts, :assign_key, :authenticated_user)
    %{source: source, error: error, store: store, assign_key: assign_key}
  end

  defp convert_source(:params, param), do: {__MODULE__, :get_token_from_params, [param]}
  defp convert_source(:header, param), do: {__MODULE__, :get_token_from_header, [param]}
  defp convert_source(:session, param), do: {__MODULE__, :get_token_from_session, [param]}
  defp convert_source(source = {module, fun, args}, _param) when is_atom(module) and is_atom(fun) and is_list(args), do: source

  def get_token_from_params(conn, param), do: {conn, conn.params[param]}
  def get_token_from_header(conn, param), do: {conn, get_first_req_header(conn, param)}
  def get_token_from_session(conn, param), do: {conn, get_session(conn, param)}

  def call(conn, opts) do
    if get_authenticated_user(conn, opts[:assign_key]) do
      conn
    else
      {module, fun, args} = opts[:source]

      apply(module, fun, [conn | args])
      |> verify_creds(opts[:store])
      |> assert_creds(opts[:error], opts[:assign_key])
    end
  end

  defp verify_creds({conn, creds}, store), do: {conn, store.get_user_data(creds)}

  defp assert_creds({conn, nil}, error, _), do: halt_with_error(conn, error)
  defp assert_creds({conn, user_data}, _, key), do: assign_user_data(conn, user_data, key)
end
