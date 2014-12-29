defmodule PlugAuth.Access do
  defprotocol RoleAdapter do
    @doc "Returns the role associated to `data` as atom"
    @fallback_to_any true
    def get_role(data)
  end

  defimpl RoleAdapter, for: Any do
    def get_role(map) when is_map(map), do: map[:role]
  end
end