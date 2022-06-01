defmodule BuildkiteTestCollector.DurationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias BuildkiteTestCollector.Duration

  describe "now/0" do
    test "it has an epoch of zero" do
      assert %{epoch: 0} = Duration.now()
    end

    test "it is the monotonic time" do
      now_us = now_us()
      %{offset: offset} = Duration.now()

      # within 0.25s
      assert_in_delta(offset, now_us, 250_000)
    end
  end

  describe "since/1" do
    test "it uses the previous duration as a starting point" do
      origin = %Duration{epoch: now_us(), offset: -10_000_000}
      origin_us = origin.epoch + origin.offset

      assert %{epoch: ^origin_us, offset: offset} = Duration.since(origin)

      assert_in_delta(offset, 10_000_000, 250_000)
    end
  end

  describe "as_seconds/1" do
    test "it returns the duration in fractional seconds" do
      duration = %Duration{epoch: 0, offset: 5_250_000}
      seconds = Duration.as_seconds(duration)

      assert seconds == 5.25
    end
  end

  describe "Jason.encode/1" do
    test "it correctly encodes the duration" do
      duration = %Duration{epoch: 0, offset: 5_250_000}

      assert {:ok, ~s|5.25|} = Jason.encode(duration)
    end
  end

  defp now_us, do: System.monotonic_time(:microsecond)
end
