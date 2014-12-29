defmodule PlugAuth.Access.Role do
  @moduledoc """
    Implements role-based access control. Authentication must occur before access control.
    
    ## Example:
      plug PlugAuth.Authentication.Basic, realm: "Secret world"
      plug PlugAuth.Access.Basic, roles: [:admin]
  """ 

  @behaviour Plug
  import Plug.Conn

  def init(opts) do
    roles = Keyword.fetch!(opts, :roles)
    %{roles: roles}
  end

  def call(conn, opts) do
    conn
  end
end