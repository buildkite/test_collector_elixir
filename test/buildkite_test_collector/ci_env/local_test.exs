defmodule BuildkiteTestCollector.CiEnv.LocalTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv.Local

  describe "detected?/0" do
    setup :clear_environment

    test "when there are not Circle CI env vars present" do
      refute Local.detected?()
    end

    test "when there are Circle CI env vars present" do
      stub_local_environment()

      assert Local.detected?()
    end
  end
end
