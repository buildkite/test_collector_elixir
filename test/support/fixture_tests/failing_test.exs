defmodule FailingTest do
  use ExUnit.Case
  @moduledoc false

  @moduletag fixture: true

  test "failing" do
    refute true
  end
end
