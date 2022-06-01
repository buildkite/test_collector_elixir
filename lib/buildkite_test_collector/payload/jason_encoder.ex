defimpl Jason.Encoder, for: BuildkiteTestCollector.Payload do
  @moduledoc """
  We implement a custom encoder because we need to inject the `"format"` key.
  """

  alias BuildkiteTestCollector.Payload

  @doc false
  @spec encode(Payload.t(), Jason.Encode.opts()) :: iodata
  def encode(%Payload{run_env: run_env, data: data}, opts) do
    %{
      format: "json",
      run_env: run_env,
      data: Enum.reverse(data)
    }
    |> Jason.Encode.map(opts)
  end
end
