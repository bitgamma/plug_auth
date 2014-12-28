defmodule PlugAuth do
  use Application

  @doc false
  def start(_type, _args) do
    PlugAuth.Supervisor.start_link()
  end
end
