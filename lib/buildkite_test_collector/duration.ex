defmodule BuildkiteTestCollector.Duration do
  defstruct usec: 0
  alias BuildkiteTestCollector.{Duration, Instant}

  @moduledoc """
  The difference between two instants with microsecond accuracy.

  The Buildkite analytics API stores all times as decimal seconds since the
  start of the test run.  Therefore we use `Duration` to calculate the span
  between two `Instant` values.
  """

  @type t :: %Duration{usec: integer()}

  @doc """
  Create a new duration from the specified number of seconds.
  """
  @spec from_seconds(number) :: t
  def from_seconds(seconds) when is_integer(seconds),
    do: %Duration{usec: seconds * 1_000_000}

  def from_seconds(seconds) when is_float(seconds),
    do: %Duration{usec: round(seconds * 1_000_000)}

  @doc """
  Create a new duration directly from microseconds.
  """
  @spec from_microseconds(number) :: t
  def from_microseconds(microseconds) when is_integer(microseconds),
    do: %Duration{usec: microseconds}

  def from_microseconds(microseconds) when is_float(microseconds),
    do: %Duration{usec: round(microseconds)}

  @doc """
  Return the elapsed time between two instants.
  """
  @spec between(Instant.t(), Instant.t()) :: t
  def between(%Instant{usec: i0}, %Instant{usec: i1}), do: %Duration{usec: i0 - i1}

  @doc """
  Return the absolute duration (ie make the duration unsigned).
  """
  @spec abs(t) :: t
  def abs(%Duration{usec: i}) when i < 0, do: %Duration{usec: -i}
  def abs(%Duration{} = duration), do: duration

  @doc """
  Returns the elapsed duration between `instant` and now.
  """
  @spec elapsed(Instant.t()) :: t
  def elapsed(%Instant{} = instant), do: Duration.between(Instant.now(), instant)

  @doc """
  The duration of the timing, in (fractional) seconds.
  """
  @spec as_seconds(t) :: number
  def as_seconds(%Duration{usec: i}), do: i / 1_000_000.0
end
