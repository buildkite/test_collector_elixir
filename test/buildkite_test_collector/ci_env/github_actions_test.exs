defmodule BuildkiteTestCollector.CiEnv.GithubActionsTest do
  @moduledoc false

  use BuildkiteTestCollector.EnvironmentCase

  alias BuildkiteTestCollector.CiEnv.GithubActions

  describe "detected?/0" do
    setup :clear_environment

    test "when there are not Circle CI env vars present" do
      refute GithubActions.detected?()
    end

    test "when there are Circle CI env vars present" do
      stub_github_actions_environment()

      assert GithubActions.detected?()
    end
  end

  describe "adapter functions" do
    setup [:clear_environment, :stub_github_actions_environment]

    test "key/0 is correctly generated", %{env: env} do
      assert "#{env["GITHUB_ACTION"]}-#{env["GITHUB_RUN_NUMBER"]}-#{env["GITHUB_RUN_ATTEMPT"]}" ==
               GithubActions.key()
    end

    test "url/0 is correctly generated", %{env: env} do
      assert "https://github.com/#{env["GITHUB_REPOSITORY"]}/actions/runs/#{env["GITHUB_RUN_ID"]}" ==
               GithubActions.url()
    end
  end
end
