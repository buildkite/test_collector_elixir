defmodule BuildkiteTestCollector.Duration do
  @moduledoc """
  The analyics API specifies start and end times in fractional seconds since the
  beginning of the test run.

  It's convenient for us to store these as a duration by specifying their start
  time and end time and then calculating the diference when serialising into
  JSON.

  Internally these times are stored as microseconds from the system's monotonic
  clock.  See `System.monotonic_time/1` for more information.
  """

  defstruct [:offset, :epoch]
  alias __MODULE__

  @type microseconds :: integer
  @type seconds :: float
  @type t :: %Duration{
          epoch: microseconds,
          offset: microseconds
        }

  @doc """
  The current time based on a zero-microsecond epoch.

  This esspentially returns a duration since the beginning of time, and is not
  that useful until you use it to as the epoch for other durations.
  """
  @spec now :: t
  def now, do: %Duration{epoch: 0, offset: now_us()}

  @doc """
  Return a new now time based on the provided epoch.
  """
  @spec since(t) :: t
  def since(%Duration{} = time) do
    new_epoch = time.epoch + time.offset
    new_offset = now_us() - new_epoch
    %Duration{epoch: new_epoch, offset: new_offset}
  end

  @doc """
  The duration of the timing, in (fractional) seconds.
  """
  @spec as_seconds(t) :: seconds
  def as_seconds(%Duration{offset: offset}), do: offset / 1_000_000.0

  defp now_us, do: System.monotonic_time(:microsecond)

  defimpl Jason.Encoder do
    @spec encode(Duration.t(), Jason.Encode.opts()) :: iodata
    def encode(timing, _opts) do
      timing
      |> Duration.as_seconds()
      |> Jason.Encode.float()
    end
  end
end
