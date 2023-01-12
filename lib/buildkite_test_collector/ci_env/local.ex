defmodule BuildkiteTestCollector.CiEnv.Local do
  @moduledoc """
  Environment detection and configuration for a local environment
  """

  use BuildkiteTestCollector.CiEnv

  @doc """
  Returns true if the environment variable `BUILDKITE_TEST_ANALYTICS_LOCAL` is set
  """
  @impl true
  def detected? do
    "BUILDKITE_TEST_ANALYTICS_LOCAL"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "local"

  @impl true
  def key, do: Ecto.UUID.generate()

  @impl true
  def collector, do: BuildkiteTestCollector.MixProject.collector_name()

  @impl true
  def version, do: BuildkiteTestCollector.MixProject.version()
end
