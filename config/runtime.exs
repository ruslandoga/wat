import Config

# openapi
openai_api_key = System.fetch_env!("OPENAI_API_KEY")

config :wat, openai_api_key: openai_api_key
