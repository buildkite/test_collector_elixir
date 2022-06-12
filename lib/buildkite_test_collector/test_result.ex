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
    location = "#{test.tags.file}:#{test.tags.line}"

    %TestResult{
      id: UUID.generate(),
      scope: extract_test_scope(test),
      name: extract_test_name(test),
      identifier: location,
      location: location,
      file_name: test.tags.file,
      result: extract_test_result(test.state),
      failure_reason: extract_failure_reason(test.state),
      failure_expanded: extract_failure_expanded(test.state),
      history: %{
        section: "top",
        start_at: start_time,
        end_at: end_time,
        duration: test.time / 1_000_000.0
      }
    }
  end

  defp extract_test_scope(%{module: module, tags: %{describe: description}})
       when is_binary(description),
       do: "#{inspect(module)} #{description}"

  defp extract_test_scope(%{module: module}), do: inspect(module)

  defp extract_test_name(%{module: module, tags: %{describe: description}, name: name})
       when is_binary(description),
       do: "#{inspect(module)} #{description} #{name}"

  defp extract_test_name(%{module: module, name: name}), do: "#{inspect(module)} #{name}"

  defp extract_test_result(nil), do: "passed"
  defp extract_test_result({:failed, _}), do: "failed"
  defp extract_test_result({:skipped, _}), do: "skipped"
  defp extract_test_result({:invalid, _}), do: "skipped"
  defp extract_test_result({:excluded, _}), do: "skipped"

  defp extract_failure_reason(
         {:failed, [{:error, %ExUnit.AssertionError{message: message}, _} | _]}
       ),
       do: message

  defp extract_failure_reason({:failed, [{:error, exception, _} | _]})
       when is_exception(exception),
       do:
         exception
         |> Exception.message()
         |> String.replace(~r/\s+/, " ")
         |> String.trim()

  defp extract_failure_reason({:failed, [{kind, payload, stacktrace} | _]}),
    do:
      Exception.format_banner(kind, payload, stacktrace)
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

  defp extract_failure_reason({:invalid, _}), do: "failure in setup_all callback"

  defp extract_failure_reason(_), do: nil

  defp extract_failure_expanded({:failed, errors}) do
    errors
    |> Enum.map(fn {kind, payload, stacktrace} ->
      message_lines =
        Exception.format_banner(kind, payload)
        |> into_lines()

      stacktrace_lines =
        stacktrace
        |> Exception.format_stacktrace()
        |> into_lines()

      %{expanded: message_lines, backtrace: stacktrace_lines}
    end)
  end

  defp extract_failure_expanded({:invalid, %ExUnit.TestModule{state: state}}),
    do: state |> extract_failure_expanded()

  defp extract_failure_expanded(_), do: nil

  defp into_lines(string),
    do:
      string
      |> String.split(~r/[\r\n]+/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(byte_size(&1) == 0))
end
