defmodule Connections do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def get() do
    GenServer.call(__MODULE__, {:get})
  end

  def add(conn) do
    GenServer.cast(__MODULE__, {:add, conn})
  end

  def remove(conn) do
    GenServer.cast(__MODULE__, {:remove, conn})
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:add, conn}, state) do
    :inet.monitor(conn)
    {:noreply, [conn | state]}
  end

  @impl true
  def handle_cast({:remove, conn}, state) do
    {:noreply, List.delete(state, conn)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :port, conn, _reason}, state) do
    remove(conn)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("Unexpected message in Connections: #{inspect(msg)}")
    {:noreply, state}
  end
end

# defmodule Test do
#   use Agent

#   def start_link(_opts) do
#     Agent.start_link(fn -> [] end, name: __MODULE__)
#   end

#   def get do
#     Agent.get(__MODULE__, & &1)
#   end

#   def add(conn) do
#     Agent.update(__MODULE__, &[conn | &1])
#   end

#   def remove(conn) do
#     Agent.update(__MODULE__, &List.delete(&1, conn))
#   end
# end
