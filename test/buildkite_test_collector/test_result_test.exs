defmodule BuildkiteTestCollector.TestResultTest do
  @moduledoc false

  use ExUnit.Case, async: false
  import BuildkiteTestCollector.ExUnitDataHelpers
  alias BuildkiteTestCollector.{Duration, Instant, TestResult}

  describe "new/1..3" do
    test "passing test" do
      result =
        passing_test()
        |> TestResult.new()

      assert result.result == "passed"
      assert result.scope == "PassingTest"
      assert result.location == "test/support/fixture_tests/passing_test.exs:5"
      assert result.file_name == "test/support/fixture_tests/passing_test.exs"
      assert result.name == "PassingTest test passing"
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

  describe "add_span/2" do
    test "adds the children list to the history when it doesn't already exist" do
      start_at = Instant.now()
      duration = Duration.from_microseconds(:rand.uniform(10_000))
      end_at = Instant.add(start_at, duration)

      span = %{
        section: :sql,
        start_at: start_at,
        end_at: end_at,
        duration: duration
      }

      result =
        excluded_test()
        |> TestResult.new()
        |> TestResult.add_span(span)

      assert [^span] = result.history.children
    end

    test "adds the span to the history children" do
      start_at = Instant.now()
      duration = Duration.from_microseconds(:rand.uniform(10_000))
      end_at = Instant.add(start_at, duration)

      span0 = %{
        section: :sql,
        start_at: start_at,
        end_at: end_at,
        duration: duration
      }

      span1 = %{
        section: :http,
        start_at: start_at,
        end_at: end_at,
        duration: duration
      }

      result =
        excluded_test()
        |> TestResult.new()
        |> TestResult.add_span(span0)
        |> TestResult.add_span(span1)

      assert [^span1, ^span0] = result.history.children
    end
  end
end
