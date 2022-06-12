defmodule BuildkiteTestCollector.TestResultTest do
  @moduledoc false

  use ExUnit.Case, async: false
  import BuildkiteTestCollector.ExUnitDataHelpers
  alias BuildkiteTestCollector.TestResult

  test "passing test" do
    result =
      passing_test()
      |> TestResult.new()

    assert result.result == "passed"
    assert result.scope == "PassingTest"
    refute result.failure_reason
    refute result.failure_expanded
  end

  test "failing test" do
    result =
      failing_test()
      |> TestResult.new()

    assert result.result == "failed"
    assert result.scope == "FailingTest"
    assert result.failure_reason == "Expected false or nil, got true"

    [%{expanded: messages, backtrace: stacktrace}] = result.failure_expanded

    assert Enum.join(stacktrace, "\n") =~ ~r/failing_test.exs:6/
    assert Enum.join(messages, "\n") =~ ~r/AssertionError/
  end

  test "skipped test" do
    result =
      skipped_test()
      |> TestResult.new()

    assert result.result == "skipped"
    assert result.scope == "SkippedTest"
    refute result.failure_reason
    refute result.failure_expanded
  end

  test "invalid test" do
    result =
      invalid_test()
      |> TestResult.new()

    assert result.result == "skipped"
    assert result.scope == "InvalidTest"
    assert result.failure_reason == "failure in setup_all callback"

    [%{expanded: messages, backtrace: stacktrace}] = result.failure_expanded

    assert Enum.join(stacktrace, "\n") =~ ~r/setup_all/
    assert Enum.join(messages, "\n") =~ ~r/RuntimeError/
  end

  test "excluded test" do
    result =
      excluded_test()
      |> TestResult.new()

    assert result.result == "skipped"
    assert result.scope == "PassingTest"
    refute result.failure_reason
    refute result.failure_expanded
  end
end
