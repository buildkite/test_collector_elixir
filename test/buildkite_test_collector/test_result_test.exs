defmodule BuildkiteTestCollector.TestResultTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias BuildkiteTestCollector.TestResult

  describe "build result for passing test" do
    test "simplest passing test" do
      result =
        TestResult.new(%ExUnit.Test{
          state: nil,
          tags: %{
            case: TestModule,
            module: TestModule,
            describe: nil,
            describe_line: nil,
            test: :"passing test",
            file: "test.exs",
            line: 12
          },
          time: 5_000_000
        })

      assert %{
               id: _,
               scope: "TestModule",
               name: "passing test",
               identifier: "test.exs:12",
               location: "test.exs:12",
               file_name: "test.exs",
               result: "passed",
               failure_reason: nil,
               failure_expanded: nil,
               history: %{
                 section: "top",
                 start_at: nil,
                 end_at: nil,
                 duration: 5.0
               }
             } = result
    end

    test "simplest failing test" do
      result =
        TestResult.new(%ExUnit.Test{
          state:
            {:failed,
             [
               {:error,
                %ExUnit.AssertionError{
                  args: :ex_unit_no_meaningful_value,
                  context: :==,
                  doctest: :ex_unit_no_meaningful_value,
                  expr: {:assert, [], [false]},
                  left: :ex_unit_no_meaningful_value,
                  message: "Expected truthy, got false",
                  right: :ex_unit_no_meaningful_value
                },
                [
                  {TestModule, :"test failing", 1,
                   [file: 'test/buildkite_test_collector/formatter_test.exs', line: 38]}
                ]}
             ]},
          tags: %{
            async: false,
            case: TestModule,
            module: TestModule,
            describe: nil,
            describe_line: nil,
            test: :"failing test",
            file: "test.exs",
            line: 12,
            registered: %{},
            test_type: :test
          },
          time: 5_000_000
        })

      assert %BuildkiteTestCollector.TestResult{
               id: _,
               scope: "TestModule",
               name: "failing test",
               identifier: "test.exs:12",
               location: "test.exs:12",
               file_name: "test.exs",
               result: "failed",
               failure_reason: "Expected truthy, got false\ncode: assert false",
               failure_expanded: [
                 %{
                   error: "ExUnit.AssertionError",
                   message: "Expected truthy, got false\ncode: assert false"
                 }
               ],
               history: %{
                 section: "top",
                 start_at: nil,
                 end_at: nil,
                 duration: 5.0
               }
             } = result
    end
  end
end
