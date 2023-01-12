defmodule BuildkiteTestCollector.CiEnv.GithubActions do
  @moduledoc """
  Environment detection and configuration for Github Actions.
  """

  use BuildkiteTestCollector.CiEnv

  @impl true
  def detected? do
    "GITHUB_RUN_NUMBER"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "github_actions"

  @impl true
  def key do
    action = System.get_env("GITHUB_ACTION")
    run_number = System.get_env("GITHUB_RUN_NUMBER")
    run_attempt = System.get_env("GITHUB_RUN_ATTEMPT")

    "#{action}-#{run_number}-#{run_attempt}"
  end

  @impl true
  def url do
    "https://github.com/#{System.get_env("GITHUB_REPOSITORY")}/actions/runs/#{System.get_env("GITHUB_RUN_ID")}"
  end

  @impl true
  def branch, do: System.get_env("GITHUB_REF")

  @impl true
  def commit_sha, do: System.get_env("GITHUB_SHA")

  @impl true
  def number, do: System.get_env("GITHUB_RUN_NUMBER")

  @impl true
  def collector, do: BuildkiteTestCollector.MixProject.collector_name()

  @impl true
  def version, do: BuildkiteTestCollector.MixProject.version()
end
