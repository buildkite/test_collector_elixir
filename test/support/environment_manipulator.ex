defmodule BuildkiteTestCollector.EnvironmentManipulator do
  @moduledoc """
  Helpers for manipulating the state of the System environment in tests.
  """

  import ExUnit.Callbacks
  alias Ecto.UUID

  @filter_env_prefixes ["CI", "BUILDKITE", "GITHUB", "CIRCLE"]

  @doc """
  Remove any CI-like environment variables and put them back after the test completes
  """
  @spec clear_environment(any) :: :ok
  def clear_environment(_context \\ nil) do
    existing_environment =
      System.get_env()
      |> Enum.filter(&variable_name_matches_prefix?/1)
      |> Enum.into(%{})

    on_exit(fn ->
      for {name, value} <- existing_environment do
        System.put_env(name, value)
      end
    end)

    for {name, _} <- existing_environment do
      System.delete_env(name)
    end

    :ok
  end

  @doc """
  Make the environment look like a buildkite CI run
  """
  @spec stub_buildkite_environment(any) :: {:ok, %{env: %{required(String.t()) => String.t()}}}
  def stub_buildkite_environment(_context \\ nil) do
    build_id = UUID.generate()

    %{
      "BUILDKITE_BUILD_ID" => build_id,
      "BUILDKITE_BUILD_URL" => "https://example.test/buildkite/#{build_id}",
      "BUILDKITE_BRANCH" => "feat/add-mr-fusion-to-delorean",
      "BUILDKITE_COMMIT" => gen_sha(),
      "BUILDKITE_BUILD_NUMBER" => :rand.uniform(999) |> to_string(),
      "BUILDKITE_JOB_ID" => :rand.uniform(999) |> to_string(),
      "BUILDKITE_MESSAGE" =>
        "Silence, Earthling! My Name Is Darth Vader. I Am An Extraterrestrial From The Planet Vulcan!"
    }
    |> stub_env()
  end

  @doc """
  Make the environment look like a Github Actions CI run
  """
  @spec stub_github_actions_environment(any) ::
          {:ok, %{env: %{required(String.t()) => String.t()}}}
  def stub_github_actions_environment(_context \\ nil) do
    %{
      "GITHUB_ACTION" => "__doc-brown_grandfather-paradox_flux-capacitor",
      "GITHUB_RUN_NUMBER" => :rand.uniform(999) |> to_string(),
      "GITHUB_RUN_ATTEMPT" => :rand.uniform(999) |> to_string(),
      "GITHUB_REPOSITORY" => "doc-brown/flux-capacitor",
      "GITHUB_REF" => "feat/add-time-circuits",
      "GITHUB_SHA" => gen_sha()
    }
    |> stub_env()
  end

  @doc """
  Make the environment look like a Circle CI run
  """
  @spec stub_circle_ci_environment(any) :: {:ok, %{env: %{required(String.t()) => String.t()}}}
  def stub_circle_ci_environment(_context \\ nil) do
    build_id = UUID.generate()

    %{
      "CIRCLE_WORKFLOW_ID" => build_id,
      "CIRCLE_BUILD_NUM" => :rand.uniform(999) |> to_string(),
      "CIRCLE_BUILD_URL" => "https://example.test/circle/#{build_id}",
      "CIRCLE_BRANCH" => "feat/add-flight-ability",
      "CIRCLE_SHA1" => gen_sha()
    }
    |> stub_env()
  end

  @doc """
  Make the environment look like a generic CI run
  """
  @spec stub_generic_ci_environment(any) :: {:ok, %{env: %{required(String.t()) => String.t()}}}
  def stub_generic_ci_environment(_context \\ nil) do
    %{
      "CI" => "true"
    }
    |> stub_env()
  end

  @doc """
  Make the environment look like a local run
  """
  @spec stub_local_environment(any) :: {:ok, %{env: %{required(String.t()) => String.t()}}}
  def stub_local_environment(_context \\ nil) do
    %{
      "BUILDKITE_TEST_ANALYTICS_LOCAL" => "true"
    }
    |> stub_env()
  end

  defp stub_env(env) do
    for {name, value} <- env do
      System.put_env(name, value)
    end

    on_exit(fn ->
      for {name, _} <- env do
        System.delete_env(name)
      end
    end)

    {:ok, env: env}
  end

  defp variable_name_matches_prefix?({name, _}),
    do: Enum.any?(@filter_env_prefixes, &String.starts_with?(name, &1))

  defp gen_sha, do: gen_sha("")
  defp gen_sha(sha) when byte_size(sha) == 40, do: sha
  defp gen_sha(sha), do: gen_sha(sha <> Enum.random(~w[0 1 2 3 4 5 6 7 8 9 a b c d e f]))
end
