# PlugAuth

PlugAuth is a collection of authentication-related plugs. It currently performs two tasks:

* Authentication
* Access control

## Usage

Add PlugAuth as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [{:plug_auth, ">= 0.0.0"}]
end
```

You should also update your applications list to include a webserver (e.g. cowboy), plug and plug_auth:

```elixir
def application do
  [applications: [:cowboy, :plug, :plug_auth]]
end
```

After you are done, run `mix deps.get` in your shell to fetch the dependencies.

## Authentication

Currently two authentication methods are supported: HTTP Basic and Token-based. In both cases you will first have to add valid credentials in the credential store. Multiple credentials can be added. The plugs provide convenience methods for this task.

### HTTP Basic Example
```elixir
creds = PlugAuth.Authentication.Basic.encode_credentials("Admin", "SecretPass")
PlugAuth.CredentialStore.Agent.put_credentials(creds, %{role: :admin})
```

### Token Example
```elixir
token = PlugAuth.Authentication.Token.generate_token
PlugAuth.CredentialStore.Agent.put_credentials(token, %{role: :admin})
```

The last argument in both cases can be any term, except nil. On succesful authentication it will be stored by the authentication plug in the assign map of the connection with the :authenticated_user atom as key. You can retrieve it using

```elixir
PlugAuth.Authentication.Utils.get_authenticated_user(conn)
```

The content of this term is not used for authentication purposes, but can be useful to store application specific information about the user (for example, the user id, its role, etc).

To perform authentication, you can add either plug to your pipeline.

### HTTP Basic Example
```elixir
plug PlugAuth.Authentication.Basic, realm: "Secret"
```
The realm parameter is optional and can be omitted. By default "Restricted Area" will be used as realm name. You can also pass the error parameter, which should be a string and will be sent instead of the default message "HTTP Authentication Required" on authentication failure (with status code 401).

### Token Example
```elixir
plug PlugAuth.Authentication.Token, source: :params, param: "auth_token", error: ~s'{"error":"authentication required"}'
```
The error parameter is optional and is treated as in the example above. The source parameter defines how to retrieve the token from the connection. Currently, the three acceptable values are: :params, :header and :session. Their name is self-explainatory. The param parameter defines the name of the parameter/HTTP header/session key where the token is stored. This should cover most cases, but if retrieving the token is more complex than that, you can pass a tuple for the source parameter. The tuple must be in the form `{MyModule, :my_function, ["param1", 42]}`. The function must accept a connection as its first argument (which will be injected as the head of the given parameter list) and any other number of parameters, which must be given in the third element of the tuple. If no additional arguments are needed, an empty list must be given.

## Access control
PlugAuth currently provides role-based access control, which can be performed after authentication. You would use it like this

```elixir
plug PlugAuth.Authentication.Basic, realm: "Secret"
plug PlugAuth.Access.Role, roles: [:admin, :developer]
```

In the example above HTTP basic authentication is used, but you could use any other authentication plug as well. The roles parameter specifies which user roles are granted access. On authentication failure the HTTP status code 403 will be sent, together with an error message which can be set using the error parameter (just like in the Authentication examples).

The role of the currently authenticated user, is read from the :authenticated_user assign of the connection. If when adding credentials you passed a map or strucutre as the user data and this map has a "role" key, then everything will work automatically. If your user data is not a map or a structure, or it does not contain the role key, you can implemented the ```PlugAuth.Access.RoleAdapter``` protocol instead.

## License
Copyright (c) 2014, Bitgamma OÜ <opensource@bitgamma.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
