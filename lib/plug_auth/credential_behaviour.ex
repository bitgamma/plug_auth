defmodule PlugAuth.CredentialBehaviour do
  use Behaviour

  defcallback get_user_data(HashDict.t) :: any
end
