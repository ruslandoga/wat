import Config

config :wat,
  ecto_repos: [Wat.Repo]

# Configures the endpoint
config :wat, WatWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: WatWeb.ErrorHTML, json: WatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Wat.PubSub,
  live_view: [signing_salt: "DX/4UIEw"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
