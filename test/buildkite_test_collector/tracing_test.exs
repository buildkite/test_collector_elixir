defmodule BuildkiteTestCollector.TracingTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Mimic
  alias BuildkiteTestCollector.{Formatter, Instant, Tracing}
  import BuildkiteTestCollector.ExUnitDataHelpers

  describe "measure/2..3" do
    test "it adds a span to the current test" do
      test = passing_test()
      test_id = {test.module, test.name}

      Formatter
      |> expect(:add_span, fn ^test_id, span ->
        assert %Instant{} = span.start_at
        assert %Instant{} = span.end_at
        assert span.duration.usec >= 69_000
        assert span.section == :annotation
        assert span.detail == "If you guys are really us, what number are we thinking of?"
      end)

      Tracing.measure(
        test.tags,
        :annotation,
        "If you guys are really us, what number are we thinking of?",
        fn ->
          Process.sleep(69)
        end
      )
    end
  end
end
