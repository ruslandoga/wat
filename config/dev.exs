import Config

config :wat, Wat.Repo,
  database: Path.expand("../wat_dev.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true
