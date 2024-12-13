defmodule ExTermbox.EventManagerTest do
  use ExUnit.Case, async: true

  alias ExTermbox.{Event, EventManager}

  defmodule BindingsStub do
    use Agent

    def start_link(_), do: Agent.start_link(fn -> [] end, name: __MODULE__)

    def poll_async(pid) do
      track({:poll_async, pid})
      {:ok, :fake_resource}
    end

    def calls, do: Agent.get(__MODULE__, & &1)

    defp track(call) do
      Agent.update(__MODULE__, fn calls -> [call | calls] end)
    end
  end

  setup do
    _bindings = start_supervised!(BindingsStub)
    pid = start_supervised!({EventManager, bindings: BindingsStub, name: nil})

    %{event_manager: pid}
  end

  describe "start_link/1" do
    test "starts the gen_server" do
      assert {:ok, pid} = EventManager.start_link(bindings: BindingsStub)
      assert Process.alive?(pid)
    end

    test "server does not begin polling until subscribers are added" do
      assert [] = BindingsStub.calls()
    end
  end

  describe "subscribe/2" do
    test "begins polling once after first subscription", %{event_manager: pid} do
      assert :ok = EventManager.subscribe(pid, self())
      assert :ok = EventManager.subscribe(pid, self())

      assert [{:poll_async, _pid}] = BindingsStub.calls()
    end

    test "notifies subscriber of polled events", %{event_manager: pid} do
      assert :ok = EventManager.subscribe(pid, self())

      send(pid, {:event, %Event{type: nil, ch: ?q}})
      assert_receive {:event, %Event{ch: ?q}}

      send(pid, {:event, %Event{type: nil, ch: ?s}})
      assert_receive {:event, %Event{ch: ?s}}
    end
  end
end
