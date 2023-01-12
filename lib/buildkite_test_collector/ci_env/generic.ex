defmodule BuildkiteTestCollector.CiEnv.Generic do
  @moduledoc """
  Environment detection and configuration for a Generic CI environment
  """

  use BuildkiteTestCollector.CiEnv

  @doc """
  Returns true if the environment variable `CI` is set
  """
  @impl true
  def detected? do
    "CI"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "generic"

  @impl true
  def key, do: Ecto.UUID.generate()

  @impl true
  def collector, do: BuildkiteTestCollector.MixProject.collector_name()

  @impl true
  def version, do: BuildkiteTestCollector.MixProject.version()
end
