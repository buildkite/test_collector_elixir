defmodule BuildkiteTestCollector.Payload do
  @moduledoc """
  A structure that represents all data about a test suite run needed for analytics.
  """

  defstruct run_env: nil, data: [], started_at: nil, data_size: 0

  alias BuildkiteTestCollector.{CiEnv, Instant, Payload, TestResult}

  @type t :: %Payload{
          run_env: serialised_environment,
          data: [TestResult.t()],
          started_at: nil | Instant.t(),
          data_size: non_neg_integer()
        }

  @type serialised_environment :: %{
          required(:CI) => String.t(),
          required(:key) => String.t(),
          optional(:number) => String.t(),
          optional(:job_id) => String.t(),
          optional(:branch) => String.t(),
          optional(:commit_sha) => String.t(),
          optional(:message) => String.t(),
          optional(:url) => String.t(),
          required(:collector) => String.t(),
          required(:version) => String.t()
        }

  @doc """
  Initialise an empty payload with the given CI environment.
  """
  @spec init(CiEnv.t()) :: t
  def init(ci_env_mod) do
    %Payload{
      run_env: serialise_env(ci_env_mod)
    }
  end

  @doc """
  Push a test pesult into the payload.
  """
  @spec push_test_result(Payload.t(), TestResult.t()) :: Payload.t()
  def push_test_result(
        %Payload{data: data, data_size: size} = payload,
        %TestResult{} = test_result
      ),
      do: %Payload{payload | data: [test_result | data], data_size: size + 1}

  @doc """
  Set the start time of the suite.
  """
  @spec set_start_time(Payload.t(), Instant.t()) :: Payload.t()
  def set_start_time(%Payload{} = payload, started_at), do: %{payload | started_at: started_at}

  defp serialise_env(ci_env_mod) do
    ~w[CI key number job_id branch commit_sha message url collector version]a
    |> Enum.reduce(%{}, fn
      :CI, env -> Map.put(env, :CI, ci_env_mod.ci())
      key, env -> Map.put(env, key, apply(ci_env_mod, key, []))
    end)
  end

  @doc """
  Convert the payload into a map ready for serialisation to JSON.

  This is done as a separate step because all timings are relative to the
  payload start time, so must be calculated.
  """
  @spec as_json(t) :: map
  def as_json(%Payload{} = payload) do
    %{
      format: "json",
      run_env: payload.run_env,
      data:
        payload.data
        |> Enum.map(&TestResult.as_json(&1, payload.started_at))
        |> Enum.reverse()
    }
  end

  defimpl Jason.Encoder do
    @doc false
    @spec encode(Payload.t(), Jason.Encode.opts()) :: iodata
    def encode(payload, opts) do
      payload
      |> Payload.as_json()
      |> Jason.Encode.map(opts)
    end
  end
end
