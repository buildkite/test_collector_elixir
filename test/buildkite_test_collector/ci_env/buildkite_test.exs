defmodule BuildkiteTestCollector.CiEnv.BuildkiteTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv.Buildkite

  describe "detected?/0" do
    setup :clear_environment

    test "when there are not Buildkite CI env vars present" do
      refute Buildkite.detected?()
    end

    test "when there are Buildkite CI env vars present" do
      stub_buildkite_environment()

      assert Buildkite.detected?()
    end
  end
end
