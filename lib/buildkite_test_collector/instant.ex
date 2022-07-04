defmodule BuildkiteTestCollector.Instant do
  defstruct usec: 0
  alias BuildkiteTestCollector.{Duration, Instant}

  @moduledoc """
  Represents a single instant with microsecond accuracy.

  Wraps monotonic time to ensure that there are no unit mistakes.

  ## Why not just use `DateTime` instead?

  Sadly, the wall clock time can move backwards and forwards between samples
  (for example if [NTP](https://www.ntp.org) is updating the clock, or during a
  daylight savings transition).  The system monotonic clock always moves
  forwards, regardless of the current wall clock time.  This means it's no good
  for measuring the absolute time, but is perfect for measuring relative time.

  See
  [erlang:monotonic_time/0](https://www.erlang.org/doc/man/erlang.html#monotonic_time-0)
  for more information.
  """

  @type t :: %Instant{usec: integer()}

  @doc """
  Return an instant representing "now" as understood by the system's monotonic
  clock.
  """
  @spec now :: t
  def now, do: %Instant{usec: System.monotonic_time(:microsecond)}

  @doc """
  Add a duration to an instant and return a new instant.
  """
  @spec add(t, Duration.t()) :: t
  def add(%Instant{usec: instant}, %Duration{usec: duration}),
    do: %Instant{usec: instant + duration}
end
