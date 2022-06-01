defmodule BuildkiteTestCollector.EnvironmentCase do
  @moduledoc """
  A wrapper around `ExUnit.Case` which disables async and imports the
  `EnvironmentManipulator` module.

  Async is disabled because we're manipulate the global state (the system
  environment).
  """

  @doc false
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(opts) do
    opts = Keyword.merge(opts, async: false)

    quote do
      use ExUnit.Case, unquote(opts)
      import BuildkiteTestCollector.EnvironmentManipulator
    end
  end
end
