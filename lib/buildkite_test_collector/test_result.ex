require Protocol
Protocol.derive(Jason.Encoder, ExUnit.AssertionError, except: [:expr])

defmodule BuildkiteTestCollector.TestResult do
  @moduledoc """
  Information about in individual test execution.

  Contains the details needed to process the analytics for the test, such as
  success/failure, failure reason, trace, etc.
  """

  # credo:disable-for-this-file Credo.Check.Design.TagTODO

  alias BuildkiteTestCollector.{Duration, TestResult}
  alias Ecto.UUID

  @derive Jason.Encoder
  defstruct [
    :id,
    :scope,
    :name,
    :identifier,
    :location,
    :file_name,
    :result,
    :failure_reason,
    :failure_expanded,
    :history
  ]

  @typedoc "Individual test summary.  Spec as yet unconfirmed."
  @type t :: %TestResult{
          id: UUID.t(),
          scope: String.t(),
          name: String.t(),
          identifier: String.t(),
          file_name: String.t(),
          result: String.t(),
          failure_reason: nil | String.t(),
          failure_expanded: nil | expanded_failure,
          history: history
        }

  @typedoc "More information about a test failure, if available"
  @type expanded_failure :: %{
          required(:expanded) => [String.t()],
          required(:backtrace) => [String.t()]
        }

  @typedoc "A trace of the test run. TBC."
  @type history :: %{
          required(:section) => String.t(),
          required(:start_at) => Duration.t(),
          required(:end_at) => Duration.t(),
          required(:duration) => number,
          optional(:children) => [history],
          optional(:detail) => map
        }

  @doc """
  Convert an `ExUnit.Test` into a Buildkite Test Analytics datum.
  """
  @spec new(ExUnit.Test.t(), Duration.t() | nil, Duration.t() | nil) :: t
  def new(%ExUnit.Test{} = test, start_time \\ nil, end_time \\ nil) do
    %TestResult{
      id: UUID.generate(),
      scope: inspect(test.tags.module),
      name: [test.tags.describe, test.tags.test] |> Enum.filter(& &1) |> Enum.join(" "),
      identifier: "#{test.tags.file}:#{test.tags.line}",
      location: "#{test.tags.file}:#{test.tags.line}",
      file_name: test.tags.file,
      result: result(test.state),
      failure_reason: failure_reason(test.state),
      failure_expanded: failure_expanded(test.state),
      history: %{
        section: "top",
        start_at: start_time,
        end_at: end_time,
        duration: test.time / 1_000_000.0
      }
    }
  end

  defp result(nil), do: "passed"
  defp result(_state), do: "failed"

  defp failure_reason(nil), do: nil

  defp failure_reason({:failed, [{:error, %{__exception__: true} = error, _} | _]}),
    do: error_message(error)

  defp failure_expanded(nil), do: nil
  defp failure_expanded({:failed, failures}), do: Enum.map(failures, &expand_failure/1)

  defp expand_failure({:error, %{__exception__: true} = error, _location}),
    do: %{
      error: inspect(error.__struct__),
      message: error_message(error)
    }

  defp error_message(error), do: error |> Exception.message() |> String.trim()
end
