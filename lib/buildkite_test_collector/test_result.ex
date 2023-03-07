require Protocol
Protocol.derive(Jason.Encoder, ExUnit.AssertionError, except: [:expr])

defmodule BuildkiteTestCollector.TestResult do
  @moduledoc """
  Information about in individual test execution.

  Contains the details needed to process the analytics for the test, such as
  success/failure, failure reason, trace, etc.
  """

  # credo:disable-for-this-file Credo.Check.Design.TagTODO

  alias BuildkiteTestCollector.{Duration, Instant, TestResult}
  alias Ecto.UUID

  defstruct [
    :id,
    :scope,
    :name,
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

  @typedoc "The test run timing and tracing"
  @type history :: %{
          required(:start_at) => Instant.t(),
          required(:end_at) => Instant.t(),
          required(:duration) => number,
          required(:children) => [span],
          optional(:detail) => map
        }

  @typedoc "A tracing span"
  @type span :: %{
          required(:section) => :http | :sql | :sleep | :annotation,
          required(:duration) => Duration.t(),
          optional(:start_at) => Instant.t(),
          optional(:end_at) => Instant.t(),
          optional(:detail) => String.t()
        }

  @doc """
  Convert an `ExUnit.Test` into a Buildkite Test Analytics datum.
  """
  @spec new(ExUnit.Test.t(), Instant.t() | nil) :: t
  def new(%ExUnit.Test{} = test, start_time \\ nil) do
    location = "#{test.tags.file}:#{test.tags.line}"
    duration = Duration.from_microseconds(test.time)
    end_time = if start_time, do: Instant.add(start_time, duration)

    %TestResult{
      id: UUID.generate(),
      scope: extract_test_scope(test),
      name: extract_test_name(test),
      location: location,
      file_name: test.tags.file,
      result: extract_test_result(test.state),
      failure_reason: extract_failure_reason(test.state),
      failure_expanded: extract_failure_expanded(test.state),
      history: %{
        start_at: start_time,
        end_at: end_time,
        duration: duration,
        children: []
      }
    }
  end

  @doc """
  Add a tracing span to the test result history.
  """
  @spec add_span(t, span) :: t
  def add_span(%TestResult{history: %{children: children} = history} = test_result, span),
    do: %TestResult{test_result | history: %{history | children: [span | children]}}

  @doc """
  Convert the test result into a map ready for serialisation to JSON.


  This is done as a separate step because all timings are relative to the
  payload start time, so must be calculated.
  """
  @spec as_json(t, Instant.t()) :: map
  def as_json(%TestResult{} = test_result, %Instant{} = started_at) do
    %{
      id: test_result.id,
      scope: test_result.scope,
      name: test_result.name,
      location: test_result.location,
      file_name: test_result.file_name,
      result: test_result.result,
      failure_reason: test_result.failure_reason,
      failure_expanded: test_result.failure_expanded,
      history: %{
        section: "top",
        start_at: elapsed_seconds(test_result.history.start_at, started_at),
        end_at: elapsed_seconds(test_result.history.end_at, started_at),
        duration: Duration.as_seconds(test_result.history.duration),
        children:
          test_result.history.children
          |> Enum.map(fn span ->
            %{
              section: to_string(span.section),
              duration: Duration.as_seconds(span.duration),
              detail: span.detail,
              start_at: elapsed_seconds(Map.get(span, :start_at), started_at),
              end_at: elapsed_seconds(Map.get(span, :end_at), started_at)
            }
          end)
          |> Enum.reverse()
      }
    }
  end

  defp elapsed_seconds(nil, _), do: nil

  defp elapsed_seconds(a, b) do
    Duration.between(a, b)
    |> Duration.abs()
    |> Duration.as_seconds()
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
