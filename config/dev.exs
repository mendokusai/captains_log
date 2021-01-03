use Mix.Config

# pull from .envrc
config :new_log, :path, System.get_env("LOG_PATH")
