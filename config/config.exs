import Config

config :wat, ecto_repos: [Wat.Repo]

import_config "#{config_env()}.exs"
