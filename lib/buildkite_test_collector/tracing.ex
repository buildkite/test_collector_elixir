defmodule BuildkiteTestCollector.Tracing do
  @moduledoc """
  Helpers for doing simple tracing in your tests.
  """

  alias BuildkiteTestCollector.{Duration, Formatter, Instant}

  @typedoc """
  ExUnit test tags (specifically the `module` and `test` tags).

  These are used to uniquely identify the test being executed.
  """
  @type tags :: %{
          required(:module) => module,
          required(:test) => atom,
          optional(atom) => any
        }

  @typedoc """
  Valid trace types.

  See [the documentation][1] for more information.

  [1]: https://buildkite.com/docs/test-analytics/importing-json#json-test-results-data-reference-span-objects
  """
  @type section :: :http | :sql | :sleep | :annotation

  @doc """
  Measure the execution time of a function and add a trace to the test analytics.

  ## Example

  ```elixir
  alias BuildkiteTestCollector.Tracing

  test "it can measure an HTTP request", tags do
    assert {:ok, _} =
             Tracing.measure(tags, :http, "The koan of Github", fn ->
               Tesla.get("https://api.github.com/zen", headers: [{"user-agent", "Tesla"}])
             end)
  end


  test "it can measure a SQL query", tags do
    import Ecto.Query

    query =
      from(tt in "time_travellers",
        where: tt.born >= 1968 and tt.born <= 1970,
        select: tt.name,
        order_by: tt.name
      )

    assert {:ok, ["Marty McFly", "Theodore Logan, III", "William Stanley Preston, Esq."]} =
             Tracing.measure(tags, :sql, inspect(query), fn ->
               MyApp.all(query)
             end)
  end
  ```
  """
  @spec measure(tags, section, nil | String.t(), (-> result)) :: result when result: any
  def measure(%{module: module, test: name} = _tags, section, detail \\ nil, callable)
      when is_function(callable, 0) do
    start_at = Instant.now()
    result = callable.()
    end_at = Instant.now()

    Formatter.add_span({module, name}, %{
      section: section,
      start_at: start_at,
      end_at: end_at,
      duration: Duration.between(end_at, start_at),
      detail: detail
    })

    result
  end
end
