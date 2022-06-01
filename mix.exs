defmodule BuildkiteTestCollector.MixProject do
  use Mix.Project
  @moduledoc false

  @version "0.1.0"

  def project do
    [
      app: :buildkite_test_collector,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: [
        "Josh Price <josh@alembic.com.au>",
        "James Harton <james.harton@alembic.com.au>"
      ],
      licenses: ["MIT"],
      links: %{
        "Source" => "htts://github.com/buildkite/text_collector_elixir"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 0.1"},
      {:ecto, "~> 3.8"},
      {:jason, "~> 1.3"},
      {:mint, "~> 1.4"},
      {:tesla, "~> 1.4"},
      {:telemetry, "~> 1.1"},

      # Dev/test
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:doctor, "~> 0.18", only: [:dev, :test]},
      {:git_ops, "~> 2.4", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.7", only: :test}
    ]
  end
end
