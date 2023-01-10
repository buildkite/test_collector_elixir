defmodule BuildkiteTestCollector.CiEnv.Buildkite do
  @moduledoc """
  Environment detection and configuration for Buildkite.
  """

  use BuildkiteTestCollector.CiEnv

  @impl true
  def detected? do
    "BUILDKITE_BUILD_ID"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "buildkite"

  @impl true
  def key, do: System.get_env("BUILDKITE_BUILD_ID")

  @impl true
  def url, do: System.get_env("BUILDKITE_BUILD_URL")

  @impl true
  def branch, do: System.get_env("BUILDKITE_BRANCH")

  @impl true
  def commit_sha, do: System.get_env("BUILDKITE_COMMIT")

  @impl true
  def number, do: System.get_env("BUILDKITE_BUILD_NUMBER")

  @impl true
  def job_id, do: System.get_env("BUILDKITE_JOB_ID")

  @impl true
  def message, do: System.get_env("BUILDKITE_MESSAGE")

  @impl true
  def collector, do: BuildkiteTestCollector.MixProject.collector_name()

  @impl true
  def version, do: BuildkiteTestCollector.MixProject.version()
end
