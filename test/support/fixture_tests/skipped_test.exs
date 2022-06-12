defmodule SkippedTest do
  use ExUnit.Case
  @moduledoc false

  @moduletag fixture: true

  @tag skip: true
  test "skipped" do
    assert true
  end
end
