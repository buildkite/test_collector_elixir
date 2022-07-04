defmodule BuildkiteTestCollector.InstantTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias BuildkiteTestCollector.{Duration, Instant}

  # Accuracy of 0.1s.
  @accuracy 100_000

  describe "now/0" do
    test "wraps the current monotonic time in microseconds" do
      monotonic_now = System.monotonic_time(:microsecond)
      instant = Instant.now()

      assert_in_delta(instant.usec, monotonic_now, @accuracy)
    end
  end

  describe "add/2" do
    test "it adds a duration to an instant" do
      instant = Instant.now()
      duration = Duration.from_seconds(30)
      new_instant = Instant.add(instant, duration)

      assert new_instant.usec == instant.usec + 30_000_000
    end
  end
end
