defmodule BuildkiteTestCollector.FormatterTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic

  import BuildkiteTestCollector.ExUnitDataHelpers
  alias BuildkiteTestCollector.{CiEnv, Duration, Formatter, HttpTransport, Payload}

  setup do
    state = %{
      payload: CiEnv.Generic |> Payload.init() |> Payload.set_start_time(Duration.now()),
      stream: false,
      timings: %{}
    }

    {:ok, state: state}
  end

  describe "init/0" do
    test "when no CI environment is detected, it doesn't start" do
      CiEnv
      |> stub(:detect_env, fn -> :error end)

      assert :ignore = Formatter.init([])
    end

    test "when a CI environment is detected, it starts normally" do
      CiEnv
      |> stub(:detect_env, fn -> {:ok, CiEnv.Generic} end)

      assert {:ok, _pid} = Formatter.init([])
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
        |> Duration.since()

      assert_in_delta since.offset, 0, 100
    end
  end

  describe ":test_finished event" do
    test "it removes the start time from the formatter state",
         %{state: state} do
      test = passing_test()
      state = %{state | timings: Map.put(state.timings, test_id(test), Duration.now())}

      {:noreply, state} = Formatter.handle_cast({:test_finished, test}, state)

      refute Map.has_key?(state.timings, test_id(test))
    end

    test "places a new test result in the payload", %{state: state} do
      test = passing_test()
      state = %{state | timings: Map.put(state.timings, test_id(test), Duration.now())}

      {:noreply, state} = Formatter.handle_cast({:test_finished, test}, state)

      assert Enum.count(state.payload.data) == 1
    end
  end

  describe ":suite_started event" do
    test "it sets the payload started_at time", %{state: state} do
      {:noreply, state} = Formatter.handle_cast({:suite_started, []}, state)

      since = state.payload.started_at |> Duration.since()

      assert_in_delta since.offset, 0, 100
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

  defp test_id(%ExUnit.Test{module: module, name: name}), do: {module, name}
end
