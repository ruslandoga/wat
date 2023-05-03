# Used by "mix format"
[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{mix,.formatter}.exs",
    "{config,lib,test,bench,dev}/**/*.{heex,ex,exs}"
  ]
]
