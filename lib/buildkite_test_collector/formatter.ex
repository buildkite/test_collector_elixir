defmodule BuildkiteTestCollector.Formatter do
  @moduledoc """
  Documentation for `BuildkiteTestCollectorFormatter`.

  See instructions https://github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit/formatter.ex

  Inspiration https://github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit/cli_formatter.ex
  """

  use GenServer

  require Logger

  alias BuildkiteTestCollector.{CiEnv, Duration, HttpTransport, Payload, TestResult}

  @type state :: %{
          payload: Payload.t(),
          timings: %{required(test_id :: {module, atom}) => Duration.t()}
        }

  @type test_id :: {module, atom}

  @impl true
  @spec init(keyword) :: {:ok, state}
  def init(_opts) do
    Process.flag(:trap_exit, true)

    case CiEnv.detect_env() do
      {:ok, env_module} ->
        state = %{
          payload: Payload.init(env_module),
          timings: %{}
        }

        {:ok, state}

      :error ->
        Logger.warn("Not starting BuildkiteTestCollector server.  No CI environment detected.")

        :ignore
    end
  end

  @impl true
  def handle_cast({:suite_started, _}, state) do
    payload =
      state.payload
      |> Payload.set_start_time(Duration.now())

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
      |> Map.put({module, name}, Duration.since(state.payload.started_at))

    {:noreply, %{state | timings: timings}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{module: module, name: name} = test}, state) do
    end_time = Duration.since(state.payload.started_at)

    case Map.pop(state.timings, {module, name}) do
      {%Duration{} = start_time, timings} ->
        test_result = TestResult.new(test, start_time, end_time)

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
        Logger.warn(
          "Received `test_finished` event for #{inspect(module)}/#{inspect(name)} out of order"
        )

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
end
