defmodule BuildkiteTestCollector.PayloadTest do
  @moduledoc false
  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.{CiEnv, Payload, TestResult}

  import BuildkiteTestCollector.ExUnitDataHelpers

  describe "init/1" do
    setup :clear_environment
    setup :stub_buildkite_environment

    test "it initialises a payload with the running environment", %{env: env} do
      assert %Payload{run_env: run_env} = Payload.init(CiEnv.Buildkite)

      assert run_env[:CI] == "buildkite"
      assert run_env.key == env["BUILDKITE_BUILD_ID"]
      assert run_env.number == env["BUILDKITE_BUILD_NUMBER"]
      assert run_env.job_id == env["BUILDKITE_JOB_ID"]
      assert run_env.branch == env["BUILDKITE_BRANCH"]
      assert run_env.commit_sha == env["BUILDKITE_COMMIT"]
      assert run_env.message == env["BUILDKITE_MESSAGE"]
      assert run_env.url =~ "http"
      assert run_env.url =~ env["BUILDKITE_BUILD_ID"]
      assert run_env.collector == BuildkiteTestCollector.MixProject.collector_name()
      assert run_env.version == BuildkiteTestCollector.MixProject.version()
    end

    test "it initialises with empty data" do
      assert %Payload{data: []} = Payload.init(CiEnv.Buildkite)
    end
  end

  describe "push_test_result/2" do
    test "it adds a test pesult to the payload data" do
      test_result = TestResult.new(passing_test())

      payload =
        CiEnv.Generic
        |> Payload.init()
        |> Payload.push_test_result(test_result)

      assert length(payload.data) == 1
    end
  end
end
