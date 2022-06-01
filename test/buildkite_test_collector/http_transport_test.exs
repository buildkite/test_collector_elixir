defmodule BuildkiteTestCollector.HttpTransportTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use Mimic

  import BuildkiteTestCollector.ExUnitDataHelpers

  alias BuildkiteTestCollector.{CiEnv, Duration, HttpTransport, Payload, TestResult}

  setup do
    old_api_token = Application.get_env(:buildkite_test_collector, :api_key)

    on_exit(fn ->
      Application.put_env(:buildkite_test_collector, :api_key, old_api_token)
    end)

    token =
      0..15
      |> Enum.map_join("", fn _ -> Enum.random(~w[0 1 2 3 4 5 6 7 8 9 a b c d e f]) end)

    Application.put_env(:buildkite_test_collector, :api_key, token)

    {:ok, token: token}
  end

  describe "send/1" do
    test "it sends the JSON encoded payload to the server", %{token: token} do
      expect(Tesla, :execute, fn module, _client, options ->
        assert module == HttpTransport

        options = options |> Enum.into(%{})

        assert options.method == :post
        assert options.url == "https://analytics-api.buildkite.com/v1/uploads"
        assert %Payload{} = options.body
        assert extract_header(options.headers, "content-type") =~ ~r/application\/json/
        assert extract_header(options.headers, "authorization") == "Token token=\"#{token}\""

        {:ok, %{body: %{}}}
      end)

      CiEnv.Generic
      |> Payload.init()
      |> Payload.set_start_time(Duration.now())
      |> HttpTransport.send()
    end
  end

  describe "maybe_send_batch/1..2" do
    setup do
      old_batch_size = Application.get_env(:buildkite_test_collector, :batch_size)

      on_exit(fn ->
        Application.put_env(:buildkite_test_collector, :batch_size, old_batch_size)
      end)

      batch_size = :rand.uniform(100) + 2

      Application.put_env(:buildkite_test_collector, :batch_size, batch_size)

      {:ok, batch_size: batch_size}
    end

    test "when there are more results than the batch size, it posts a batch and returns a modified payload",
         %{
           batch_size: batch_size
         } do
      payload =
        CiEnv.Generic
        |> Payload.init()
        |> Payload.set_start_time(Duration.now())

      total_result_size = (batch_size * 1.5) |> trunc()

      payload =
        1..total_result_size
        |> Enum.reduce(payload, fn _, payload ->
          Payload.push_test_result(payload, TestResult.new(passing_test()))
        end)

      expect(Tesla, :execute, fn _module, _client, options ->
        payload = Keyword.fetch!(options, :body)

        assert length(payload.data) == batch_size
        assert payload.data_size == batch_size

        {:ok, %{body: %{}}}
      end)

      assert {:ok, new_payload} = HttpTransport.maybe_send_batch(payload)

      assert new_payload.run_env == payload.run_env
      assert new_payload.data_size == total_result_size - batch_size
    end

    test "when there are less results than the batch size, it returns the payload unchanged" do
      payload =
        CiEnv.Generic
        |> Payload.init()
        |> Payload.set_start_time(Duration.now())

      assert {:ok, ^payload} = HttpTransport.maybe_send_batch(payload)
    end
  end

  defp extract_header(headers, header) do
    Enum.find_value(headers, fn {name, value} ->
      if header == name, do: value
    end)
  end
end
