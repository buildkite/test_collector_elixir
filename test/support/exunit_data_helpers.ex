defmodule BuildkiteTestCollector.ExUnitDataHelpers do
  @moduledoc """
  Fixture test results.
  """

  @doc false
  @spec passing_test :: ExUnit.Test.t()
  def passing_test do
    %ExUnit.Test{
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
      time: 5
    }
  end

  @doc false
  @spec failing_test :: ExUnit.Test.t()
  def failing_test do
    %ExUnit.Test{
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
      time: 5
    }
  end
end
