defmodule BuildkiteTestCollector.CiEnv.GenericTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv.Generic

  describe "detected?/0" do
    setup :clear_environment

    test "when there are not Circle CI env vars present" do
      refute Generic.detected?()
    end

    test "when there are Circle CI env vars present" do
      stub_generic_ci_environment()

      assert Generic.detected?()
    end
  end
end
