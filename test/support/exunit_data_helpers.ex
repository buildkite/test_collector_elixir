defmodule BuildkiteTestCollector.ExUnitDataHelpers do
  @moduledoc """
  Fixture test results.
  """

  @doc false
  @spec passing_test :: ExUnit.Test.t()
  def passing_test do
    %ExUnit.Test{
      case: PassingTest,
      logs: "",
      module: PassingTest,
      name: :"test passing",
      state: nil,
      tags: %{
        async: false,
        case: PassingTest,
        describe: nil,
        describe_line: nil,
        file: "test/support/fixture_tests/passing_test.exs",
        line: 5,
        module: PassingTest,
        registered: %{},
        test: :"test passing",
        test_type: :test
      },
      time: 3
    }
  end

  @doc false
  @spec failing_test :: ExUnit.Test.t()
  def failing_test do
    %ExUnit.Test{
      case: FailingTest,
      logs: "",
      module: FailingTest,
      name: :"test failing",
      state:
        {:failed,
         [
           {:error,
            %ExUnit.AssertionError{
              args: :ex_unit_no_meaningful_value,
              context: :==,
              doctest: :ex_unit_no_meaningful_value,
              expr: {:refute, [], [true]},
              left: :ex_unit_no_meaningful_value,
              message: "Expected false or nil, got true",
              right: :ex_unit_no_meaningful_value
            },
            [
              {FailingTest, :"test failing", 1,
               [file: ~c"test/support/fixture_tests/failing_test.exs", line: 6]}
            ]}
         ]},
      tags: %{
        async: false,
        case: FailingTest,
        describe: nil,
        describe_line: nil,
        file: "test/support/fixture_tests/failing_test.exs",
        line: 5,
        module: FailingTest,
        registered: %{},
        test: :"test failing",
        test_type: :test
      },
      time: 4020
    }
  end

  @doc false
  @spec skipped_test :: ExUnit.Test.t()
  def skipped_test do
    %ExUnit.Test{
      case: SkippedTest,
      logs: "",
      module: SkippedTest,
      name: :"test skipped",
      state: {:skipped, "due to skip tag"},
      tags: %{
        async: false,
        describe: nil,
        describe_line: nil,
        file: "test/support/fixture_tests/skipped_test.exs",
        line: 6,
        registered: %{},
        skip: true,
        test_type: :test
      },
      time: 0
    }
  end

  @doc false
  @spec invalid_test :: ExUnit.Test.t()
  def invalid_test do
    %ExUnit.Test{
      case: InvalidTest,
      logs: "",
      module: InvalidTest,
      name: :"test invalid",
      state:
        {:invalid,
         %ExUnit.TestModule{
           file: "test/support/fixture_tests/invalid_test.exs",
           name: InvalidTest,
           state:
             {:failed,
              [
                {:error, %RuntimeError{message: "hell"},
                 [
                   {InvalidTest, :__ex_unit_setup_all_0, 1,
                    [
                      file: ~c"test/support/fixture_tests/invalid_test.exs",
                      line: 6,
                      error_info: %{module: Exception}
                    ]},
                   {InvalidTest, :__ex_unit__, 2,
                    [file: ~c"test/support/fixture_tests/invalid_test.exs", line: 1]}
                 ]}
              ]},
           tests: [
             %ExUnit.Test{
               case: InvalidTest,
               logs: "",
               module: InvalidTest,
               name: :"test invalid",
               state: nil,
               tags: %{
                 async: false,
                 describe: nil,
                 describe_line: nil,
                 file: "test/support/fixture_tests/invalid_test.exs",
                 line: 9,
                 registered: %{},
                 test_type: :test
               },
               time: 0
             }
           ]
         }},
      tags: %{
        async: false,
        describe: nil,
        describe_line: nil,
        file: "test/support/fixture_tests/invalid_test.exs",
        line: 9,
        module: InvalidTest,
        registered: %{},
        test: :"test invalid",
        test_type: :test
      },
      time: 0
    }
  end

  @doc false
  @spec excluded_test :: ExUnit.Test.t()
  def excluded_test do
    %ExUnit.Test{
      case: PassingTest,
      logs: "",
      module: PassingTest,
      name: :"test passing",
      state: {:excluded, "due to test filter"},
      tags: %{
        async: false,
        describe: nil,
        describe_line: nil,
        file: "test/support/fixture_tests/passing_test.exs",
        line: 5,
        registered: %{},
        test_type: :test
      },
      time: 0
    }
  end
end
