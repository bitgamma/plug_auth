defmodule PlugAuth.CredentialStore do
  use Behaviour

  @callback get_user_data(HashDict.t) :: any
end
