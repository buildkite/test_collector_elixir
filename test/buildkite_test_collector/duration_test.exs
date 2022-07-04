defmodule BuildkiteTestCollector.DurationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias BuildkiteTestCollector.{Duration, Instant}

  # Accuracy of 0.1s.
  @accuracy 100_000

  describe "from_seconds/1" do
    test "it correctly converts integer seconds into microseconds" do
      assert %{usec: 30_000_000} = Duration.from_seconds(30)
    end

    test "it rounds float seconds into microseconds" do
      assert %{usec: 333_333} = Duration.from_seconds(1.0 / 3.0)
    end
  end

  describe "from_microseconds/1" do
    test "it stores integer microseconds directly" do
      assert %{usec: 30} = Duration.from_microseconds(30)
    end

    test "it rounds float microseconds" do
      assert %{usec: 31} = Duration.from_microseconds(30.5)
    end
  end

  describe "between/2" do
    test "it correctly calculates the duration between two instants" do
      i0 = Instant.now()
      i1 = seconds_from_now(30)
      duration = Duration.between(i0, i1)

      assert_in_delta(duration.usec, -30_000_000, @accuracy)
    end
  end

  describe "abs/1" do
    test "it converts a negative duration into a positive duration" do
      duration =
        %Duration{usec: -30_000_000}
        |> Duration.abs()

      assert duration.usec == 30_000_000
    end

    test "it doesn't change the sign of a positive duration" do
      duration =
        %Duration{usec: 30_000_000}
        |> Duration.abs()

      assert duration.usec == 30_000_000
    end
  end

  describe "since/1" do
    test "when the instant is in the future, it returns a negative duration" do
      instant = seconds_from_now(30)
      duration = Duration.elapsed(instant)

      assert_in_delta(duration.usec, -30_000_000, @accuracy)
    end

    test "when the instant is in the past, it returns a positive duration" do
      instant = seconds_from_now(-30)
      duration = Duration.elapsed(instant)

      assert_in_delta(duration.usec, 30_000_000, @accuracy)
    end
  end

  def seconds_from_now(seconds) do
    Instant.now()
    |> Instant.add(Duration.from_seconds(seconds))
  end
end
