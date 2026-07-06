import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/overseer start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :overseer, OverseerWeb.Endpoint, server: true
end

# Load variables from .env into the process environment for local development
# and testing. Phoenix does not read .env on its own, so without this the
# AWS credentials would be missing and ExAws would fall back to EC2 instance
# metadata (and time out). In :prod the host supplies real environment
# variables, so we skip the file there.
if config_env() in [:dev, :test] do
  env_file = Path.expand("../.env", __DIR__)

  if File.exists?(env_file) do
    for raw_line <- File.stream!(env_file) do
      line = raw_line |> String.trim() |> String.replace_prefix("export ", "")

      if line != "" and not String.starts_with?(line, "#") do
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            value = value |> String.trim() |> String.trim("\"") |> String.trim("'")
            System.put_env(String.trim(key), value)

          _ ->
            :ok
        end
      end
    end
  end
end

# AWS configuration for ExAws, used by the LLM module's Bedrock calls.
# - region: ExAws does NOT read AWS_REGION automatically, so set it here.
# - bedrock host: model invocation uses the "bedrock-runtime" endpoint,
#   not the default "bedrock" management endpoint.
# Credentials are picked up from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
# via ExAws's default credential chain (now that .env is loaded above).
aws_region = System.get_env("AWS_REGION") || "ap-southeast-1"

config :ex_aws,
  region: aws_region

config :ex_aws, :bedrock, host: "bedrock-runtime.#{aws_region}.amazonaws.com"

# HydraDB REST API client config. The key comes from HYDRADB_API_KEY (loaded
# from .env above in dev/test); the base URL is overridable but defaults to the
# documented host.
config :overseer, Overseer.HydraDB,
  base_url: System.get_env("HYDRADB_BASE_URL", "https://api.hydradb.com"),
  api_key: System.get_env("HYDRADB_API_KEY")

config :overseer, OverseerWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :overseer, Overseer.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :overseer, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :overseer, OverseerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :overseer, OverseerWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :overseer, OverseerWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
