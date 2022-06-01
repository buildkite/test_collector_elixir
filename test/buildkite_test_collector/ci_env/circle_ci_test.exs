defmodule BuildkiteTestCollector.CiEnv.CircleCiTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv.CircleCi

  describe "detected?/0" do
    setup :clear_environment

    test "when there are not Circle CI env vars present" do
      refute CircleCi.detected?()
    end

    test "when there are Circle CI env vars present" do
      stub_circle_ci_environment()

      assert CircleCi.detected?()
    end
  end

  describe "adapter functions" do
    setup [:clear_environment, :stub_circle_ci_environment]

    test "key/0 is correctly generated", %{env: env} do
      assert "#{env["CIRCLE_WORKFLOW_ID"]}-#{env["CIRCLE_BUILD_NUM"]}" == CircleCi.key()
    end
  end
end
