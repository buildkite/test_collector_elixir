defmodule BuildkiteTestCollector.CiEnvTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv

  describe "detect_env/0" do
    setup :clear_environment

    test "when there are no CI environment variables, it returns an error" do
      assert :error = CiEnv.detect_env()
    end

    test "when there Buildkite CI environment variables present" do
      stub_buildkite_environment()

      assert {:ok, CiEnv.Buildkite} = CiEnv.detect_env()
    end

    test "when there are Github Actions environment variables present" do
      stub_github_actions_environment()

      assert {:ok, CiEnv.GithubActions} = CiEnv.detect_env()
    end

    test "when there are CircleCi environment variables present" do
      stub_circle_ci_environment()

      assert {:ok, CiEnv.CircleCi} = CiEnv.detect_env()
    end

    test "when there are generic CI environment variables present" do
      stub_generic_ci_environment()

      assert {:ok, CiEnv.Generic} = CiEnv.detect_env()
    end

    test "when there are local dev environment variables present" do
      stub_local_environment()

      assert {:ok, CiEnv.Local} = CiEnv.detect_env()
    end
  end
end
