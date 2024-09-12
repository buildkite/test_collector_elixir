defmodule BuildkiteTestCollector.Formatter do
  @moduledoc """
  Documentation for `BuildkiteTestCollectorFormatter`.

  See instructions https://github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit/formatter.ex

  Inspiration https://github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit/cli_formatter.ex
  """

  use GenServer

  require Logger

  alias BuildkiteTestCollector.{CiEnv, Duration, HttpTransport, Instant, Payload, TestResult}

  @typedoc """
  Unique identifier for tests.

  Contains the module that the test is defined in, and the name of the test as an atom.
  """
  @type test_id :: {module, atom}

  @typedoc false
  @type state :: %{
          payload: Payload.t(),
          timings: %{required(test_id) => Duration.t()},
          spans: %{required(test_id) => [TestResult.span()]}
        }

  @typedoc """
  The ExUnit tags, (specifically `module` and `test` tags)
  """
  @type tags :: %{
          required(:module) => module,
          required(:test) => atom,
          optional(atom) => any
        }

  @typedoc """
  A trace with known start and end time.
  """
  @type span_with_start_and_end_at :: %{
          required(:section) => :http | :sql | :sleep | :annotation,
          required(:start_at) => Instant.t(),
          required(:end_at) => Instant.t(),
          optional(:duration) => Duration.t(),
          optional(:detail) => String.t()
        }

  @typedoc """
  A trace with a known duration.
  """
  @type span_with_duration :: %{
          required(:section) => :http | :sql | :sleep | :annotation,
          required(:duration) => Duration.t(),
          optional(:detail) => String.t()
        }

  @doc """
  Manually add a trace span to the currently running test.

  You can add timing information about sql queries, http requests, etc to your
  test analytics.

  It's probably better to use the helpers in the `Tracing` module.

  ## Example

  ```elixir
  alias BuildkiteTestCollector.{Formatter, Instant}

  test "example of instrumenting a query", tags do
    start_at = Instant.now()

    MyApp.Repo.all(my_complicated_query)

    end_at = Instant.now()

    Formatter.add_span(tags, %{
      start_at: start_at,
      end_at: end_at,
      section: :sql,
      detail: inspect(my_complicated_query)
    })
  end
  ```
  """
  @spec add_span(tags | test_id, span_with_start_and_end_at() | span_with_duration()) :: :ok
  def add_span(%{module: module, test: name} = _tags, span),
    do: GenServer.cast(__MODULE__, {:add_span, {module, name}, span})

  def add_span({module, name} = _test_id, span),
    do: GenServer.cast(__MODULE__, {:add_span, {module, name}, span})

  @impl true
  @spec init(keyword) :: {:ok, state}
  def init(opts) do
    Process.flag(:trap_exit, true)

    case CiEnv.detect_env() do
      {:ok, env_module} ->
        state = %{
          payload: Payload.init(env_module),
          timings: %{},
          spans: %{}
        }

        if Keyword.get(opts, :register, true),
          do: Process.register(self(), __MODULE__)

        {:ok, state}

      :error ->
        Logger.warning("Not starting BuildkiteTestCollector server.  No CI environment detected.")

        :ignore
    end
  end

  @impl true
  def handle_cast({:suite_started, _}, state) do
    payload =
      state.payload
      |> Payload.set_start_time(Instant.now())

    {:noreply, %{state | payload: payload}}
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    with {:error, reason} <- HttpTransport.send(state.payload) do
      Logger.error("Error sending test suite analytics: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  def handle_cast({:test_started, %ExUnit.Test{module: module, name: name}}, state) do
    timings =
      state.timings
      |> Map.put({module, name}, Instant.now())

    {:noreply, %{state | timings: timings}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{module: module, name: name} = test}, state) do
    test_id = {module, name}
    {test_spans, spans} = Map.pop(state.spans, test_id, [])
    state = %{state | spans: spans}

    case Map.pop(state.timings, test_id) do
      {%Instant{} = start_time, timings} ->
        test_result = TestResult.new(test, start_time)
        test_result = Enum.reduce(test_spans, test_result, &TestResult.add_span(&2, &1))

        payload =
          state.payload
          |> Payload.push_test_result(test_result)

        case HttpTransport.maybe_send_batch(payload) do
          {:ok, payload} ->
            {:noreply, %{state | timings: timings, payload: payload}}

          {:error, reason} ->
            Logger.warning("Error sending test suite analytics batch: #{inspect(reason)}")
            {:noreply, %{state | timings: timings, payload: payload}}
        end

      {nil, _timings} ->
        Logger.warning(
          "Received `test_finished` event for #{inspect(module)}/#{inspect(name)} out of order"
        )

        {:noreply, state}
    end
  end

  def handle_cast({:add_span, {module, name}, span}, state) do
    case refine_span(span) do
      {:ok, span} ->
        spans =
          state.spans
          |> Map.update({module, name}, [span], &[span | &1])

        {:noreply, %{state | spans: spans}}

      :error ->
        {:noreply, state}
    end
  end

  def handle_cast(_, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{payload: %{data_size: 0}}), do: :ok

  def terminate(_reason, state) do
    with {:error, reason} <- HttpTransport.send(state.payload) do
      Logger.error("Error sending test suite analytics: #{inspect(reason)}")
    end
  end

  defguardp valid_section?(section) when section in [:http, :sql, :sleep, :annotation]

  defp refine_span(%{duration: duration, section: section} = span)
       when is_struct(duration, Duration) and valid_section?(section),
       do: {:ok, span}

  defp refine_span(%{start_at: start_at, end_at: end_at, section: section} = span)
       when is_struct(start_at, Instant) and is_struct(end_at, Instant) and
              valid_section?(section),
       do: {:ok, Map.put(span, :duration, Duration.between(end_at, start_at))}

  defp refine_span(span) do
    Logger.warning("Invalid span: #{inspect(span)}")
    :error
  end
end
