import Config

config :buildkite_test_collector,
  api_key: System.get_env("BUILDKITE_ANALYTICS_TOKEN")
