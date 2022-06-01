defmodule BuildkiteTestCollector.CiEnv.Generic do
  @moduledoc """
  Environment detection and configuraiton for a Generic CI environment
  """

  use BuildkiteTestCollector.CiEnv

  @doc """
  Returns true if the environment variable `CI` is set
  """
  @impl true
  def detected? do
    "CI"
    |> System.get_env()
    |> is_binary()
  end

  @impl true
  def ci, do: "generic"

  @impl true
  def key, do: Ecto.UUID.generate()
end
