defmodule BuildkiteTestCollector.FormatterTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic

  import BuildkiteTestCollector.ExUnitDataHelpers
  alias BuildkiteTestCollector.{CiEnv, Duration, Formatter, HttpTransport, Instant, Payload}

  setup do
    state = %{
      payload: CiEnv.Generic |> Payload.init() |> Payload.set_start_time(Instant.now()),
      stream: false,
      timings: %{},
      spans: %{}
    }

    {:ok, state: state}
  end

  describe "init/0" do
    test "when no CI environment is detected, it doesn't start" do
      CiEnv
      |> stub(:detect_env, fn -> :error end)

      assert :ignore = Formatter.init(register: false)
    end

    test "when a CI environment is detected, it starts normally" do
      CiEnv
      |> stub(:detect_env, fn -> {:ok, CiEnv.Generic} end)

      assert {:ok, _pid} = Formatter.init(register: false)
    end
  end

  describe ":test_started event" do
    test "it places the start time in the formatter state",
         %{state: state} do
      test = passing_test()

      {:noreply, state} = Formatter.handle_cast({:test_started, test}, state)

      since =
        state.timings
        |> Map.get(test_id(test))
        |> Duration.elapsed()

      assert_in_delta since.usec, 0, 100
    end
  end

  describe ":test_finished event" do
    test "it removes the start time from the formatter state",
         %{state: state} do
      test = passing_test()
      state = %{state | timings: Map.put(state.timings, test_id(test), Instant.now())}

      {:noreply, state} = Formatter.handle_cast({:test_finished, test}, state)

      refute Map.has_key?(state.timings, test_id(test))
    end

    test "places a new test result in the payload", %{state: state} do
      test = passing_test()
      state = %{state | timings: Map.put(state.timings, test_id(test), Instant.now())}

      {:noreply, state} = Formatter.handle_cast({:test_finished, test}, state)

      assert Enum.count(state.payload.data) == 1
    end

    test "it moves any spans into the test history", %{state: state} do
      test = passing_test()

      span = %{
        section: :annotation,
        duration: Duration.from_microseconds(100)
      }

      state =
        state
        |> Map.merge(%{
          timings: Map.put(state.timings, test_id(test), Instant.now()),
          spans: Map.put(state.spans, test_id(test), [span])
        })

      {:noreply, state} = Formatter.handle_cast({:test_finished, test}, state)
      [test_result] = state.payload.data

      assert [^span] = test_result.history.children
    end
  end

  describe ":suite_started event" do
    test "it sets the payload started_at time", %{state: state} do
      {:noreply, state} = Formatter.handle_cast({:suite_started, []}, state)

      since = state.payload.started_at |> Duration.elapsed()

      assert_in_delta since.usec, 0, 100
    end
  end

  describe ":suite_finished event" do
    test "it sends the payload to the API", %{state: state} do
      HttpTransport
      |> expect(:send, fn payload ->
        assert payload == state.payload
      end)

      Formatter.handle_cast({:suite_finished, %{}}, state)
    end
  end

  describe ":add_span event" do
    test "when the span has a valid section and duration, it stores the span in the state", %{
      state: state
    } do
      test_id = test_id(passing_test())

      span = %{
        section: :annotation,
        duration: Duration.from_microseconds(100)
      }

      assert {:noreply, state} = Formatter.handle_cast({:add_span, test_id, span}, state)
      assert [^span] = Map.get(state.spans, test_id)
    end

    test "when the span has a valid section and start and end times, it adds the duration and stores the span in the state",
         %{state: state} do
      test_id = test_id(passing_test())

      start_at = Instant.now()
      end_at = Instant.add(start_at, Duration.from_seconds(13))

      span = %{section: :sql, start_at: start_at, end_at: end_at}

      assert {:noreply, state} = Formatter.handle_cast({:add_span, test_id, span}, state)
      assert [span] = Map.get(state.spans, test_id)
      assert span.duration.usec == 13_000_000
    end
  end

  defp test_id(%{module: module, name: name}), do: {module, name}
end
