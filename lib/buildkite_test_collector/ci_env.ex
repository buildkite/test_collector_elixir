defmodule BuildkiteTestCollector.CiEnv do
  @moduledoc """
  A behaviour for representing CI environments.

  Implemented for each CI environment.
  """

  alias __MODULE__

  @doc """
  Returns true if the specified environment is present
  """
  @callback detected?() :: boolean

  @doc """
  Returns the name of the environment snake_case
  """
  @callback ci() :: String.t()

  @doc """
  A unique identifier for this test run
  """
  @callback key() :: nil | String.t()

  @doc """
  The URL for more information about this run
  """
  @callback url() :: nil | String.t()

  @doc """
  The git branch or tag that is being tested
  """
  @callback branch() :: nil | String.t()

  @doc """
  The git commit SHA for the code under test
  """
  @callback commit_sha() :: nil | String.t()

  @doc """
  A unique number for the run
  """
  @callback number() :: nil | String.t()

  @doc """
  A unique job ID
  """
  @callback job_id() :: nil | String.t()

  @doc """
  Any additional message from the CI environment
  """
  @callback message() :: nil | String.t()

  @doc """
  Name of test collector
  """
  @callback collector() :: String.t()
  @doc """
  Version of test collector
  """
  @callback version() :: String.t()

  @optional_callbacks url: 0, branch: 0, commit_sha: 0, number: 0, job_id: 0, message: 0

  @doc """
  Detect if the current process is running in a supported CI environment.
  """
  @spec detect_env :: {:ok, module} | :error
  def detect_env do
    [CiEnv.Buildkite, CiEnv.CircleCi, CiEnv.GithubActions, CiEnv.Generic, CiEnv.Local]
    |> Enum.find_value(:error, fn module ->
      if module.detected?(), do: {:ok, module}
    end)
  end

  @doc """
  Implements defaults for the optional callbacks.
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(_) do
    quote do
      @behaviour BuildkiteTestCollector.CiEnv

      def url, do: nil
      def branch, do: nil
      def commit_sha, do: nil
      def number, do: nil
      def job_id, do: nil
      def message, do: nil

      defoverridable url: 0, branch: 0, commit_sha: 0, number: 0, job_id: 0, message: 0
    end
  end
end
