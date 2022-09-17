import Config

config :pult,
  port: System.get_env("PORT", "4001") |> String.to_integer()

config :pult,
  chunk_size: System.get_env("CHUNK_SIZE", "1024") |> String.to_integer()
