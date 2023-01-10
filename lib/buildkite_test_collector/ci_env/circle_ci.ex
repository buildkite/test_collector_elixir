defmodule BuildkiteTestCollector.CiEnv.CircleCi do
  @moduledoc """
  Environment detection and configuration for Circle CI.
  """

  use BuildkiteTestCollector.CiEnv

  @impl true
  def detected? do
    "CIRCLE_BUILD_NUM"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "circleci"

  @impl true
  def key do
    workflow_id = System.get_env("CIRCLE_WORKFLOW_ID")
    build_num = System.get_env("CIRCLE_BUILD_NUM")

    "#{workflow_id}-#{build_num}"
  end

  @impl true
  def url, do: System.get_env("CIRCLE_BUILD_URL")

  @impl true
  def branch, do: System.get_env("CIRCLE_BRANCH")

  @impl true
  def commit_sha, do: System.get_env("CIRCLE_SHA1")

  @impl true
  def number, do: System.get_env("CIRCLE_BUILD_NUM")

  @impl true
  def collector, do: BuildkiteTestCollector.MixProject.collector_name()

  @impl true
  def version, do: BuildkiteTestCollector.MixProject.version()
end
