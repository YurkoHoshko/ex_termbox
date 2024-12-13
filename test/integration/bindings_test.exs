defmodule ExTermbox.Integration.BindingsTest do
  use ExUnit.Case, async: false

  alias ExTermbox.Bindings

  setup do
    on_exit(fn ->
      _ = Bindings.shutdown()
    end)

    :ok
  end

  describe "init/0" do
    @tag :integration
    test "returns an error if already running" do
      assert :ok = Bindings.init()
      assert {:error, :already_running} = Bindings.init()

      assert :ok = Bindings.shutdown()
      assert :ok = Bindings.init()
    end
  end

  describe "shutdown/0" do
    @tag :integration
    test "returns :ok if sucessfully shutdown" do
      :ok = Bindings.init()

      assert :ok = Bindings.shutdown()
    end

    @tag :integration
    test "returns an error if not running" do
      assert {:error, :not_running} = Bindings.shutdown()
    end
  end
end
