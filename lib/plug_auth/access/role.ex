defmodule PlugAuth.Access.Role do
  @moduledoc """
    Implements role-based access control. Authentication must occur before access control.

    ## Example:
      plug PlugAuth.Authentication.Basic, realm: "Secret world"
      plug PlugAuth.Access.Role, roles: [:admin]
  """

  @behaviour Plug
  import Plug.Conn

  def init(opts) do
    roles = Keyword.fetch!(opts, :roles)
    error = Keyword.get(opts, :error, "HTTP Forbidden")
    %{roles: roles, error: error}
  end

  def call(conn, opts) do
    conn
    |> get_user()
    |> get_roles()
    |> assert_role(opts[:roles], opts[:error])
  end

  defp get_user(conn), do: {conn, PlugAuth.Authentication.Utils.get_authenticated_user(conn)}
  defp get_roles({conn, nil}), do: {conn, nil}
  defp get_roles({conn, user}), do: {conn, PlugAuth.Access.RolesAdapter.get_roles(user)}
  defp assert_role({conn, user_roles}, roles, error) do
    found_roles = Enum.filter(user_roles, fn(role) -> role in roles end)

    if found_roles != [] do
      assign(conn, :authenticated_roles, found_roles)
    else
      halt_forbidden(conn, error)
    end
  end

  defp halt_forbidden(conn, error) when is_function(error) do
    error.(conn)
    |> halt
  end
  defp halt_forbidden(conn, error) do
    conn
    |> send_resp(403, error)
    |> halt
  end
end
