defmodule BackendTest do
  use BackendWeb.ConnCase, async: true
  use BackendWeb, :db

  test "first" do
    assert true
  end
end
