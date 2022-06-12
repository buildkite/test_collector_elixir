defmodule InvalidTest do
  use ExUnit.Case
  @moduledoc false

  @moduletag fixture: true

  setup_all do
    raise "hell"
  end

  test "invalid" do
    assert true
  end
end
