defmodule PlugAuth.Access do
  defprotocol RolesAdapter do
    @doc "Returns the roles associated to `data` as atom"
    @fallback_to_any true
    def get_roles(data)
  end

  defimpl RolesAdapter, for: Any do
    def get_roles(%{:role => role}), do: [role]
    def get_roles(%{"role" => role}), do: [role]
    def get_roles(%{:roles => roles}), do: roles
    def get_roles(%{"roles" => roles}), do: roles
    def get_roles(_), do: nil
  end
end
