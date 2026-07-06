defmodule Overseer.Repo do
  use Ecto.Repo,
    otp_app: :overseer,
    adapter: Ecto.Adapters.Postgres
end
