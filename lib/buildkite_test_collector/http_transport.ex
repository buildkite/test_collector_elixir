defmodule BuildkiteTestCollector.HttpTransport do
  @moduledoc """
  Handles encoding and transmitting payloads to Buildkite's test analytics API
  via HTTP.
  """

  alias BuildkiteTestCollector.Payload
  use Tesla, only: [:post], docs: false

  adapter Tesla.Adapter.Mint
  plug Tesla.Middleware.JSON, engine: Jason

  @doc """
  Send a `Payload` to Buildkite's test analytics API.
  """
  @spec send(Payload.t()) :: {:ok, map} | {:error, any}
  def send(payload) do
    case post(endpoint(), payload, headers: headers()) do
      {:ok, _} -> {:ok, %{payload: %{data: [], data_size: 0}}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  If the payload contains at least the configured batch size (default 500) test
  results, then send a batch to the API.
  """
  @spec maybe_send_batch(Payload.t()) :: {:ok, Payload.t()} | {:error, any}
  def maybe_send_batch(payload), do: maybe_send_batch(payload, batch_size())

  @doc false
  @spec maybe_send_batch(Payload.t(), pos_integer()) :: {:ok, Payload.t()} | {:error, any}
  def maybe_send_batch(%{data_size: data_size, data: data} = payload, batch_size)
      when data_size >= batch_size do
    {this_batch, next_batch} = Enum.split(data, batch_size)
    payload_to_send = %{payload | data: this_batch, data_size: length(this_batch)}
    payload_to_return = %{payload | data: next_batch, data_size: length(next_batch)}

    case send(payload_to_send) do
      {:ok, _} -> {:ok, payload_to_return}
      {:error, reason} -> {:error, reason}
    end
  end

  def maybe_send_batch(payload, _batch_size), do: {:ok, payload}

  defp headers,
    do: [
      {"content-type", "application/json"},
      {"authorization", "Token token=\"#{api_key()}\""}
    ]

  defp endpoint,
    do:
      Application.get_env(
        :buildkite_test_collector,
        :api_endpoint,
        "https://analytics-api.buildkite.com/v1/uploads"
      )

  defp api_key, do: Application.fetch_env!(:buildkite_test_collector, :api_key)

  defp batch_size, do: Application.get_env(:buildkite_test_collector, :batch_size, 500)
end
