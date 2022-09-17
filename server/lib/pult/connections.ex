# switched from Agent to GenServer to be able to handle info messages from :inet.monitor/1
defmodule Pult.Connections do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def get_all() do
    GenServer.call(__MODULE__, {:get})
  end

  def get_by_id(socket_id) do
    case get_all() |> Enum.find(nil, fn {id, _} -> id === socket_id end) do
      nil -> nil
      {_, socket} -> socket
    end
  end

  def get_all_except(socket) do
    get_all() |> Enum.filter(fn {_, s} -> s !== socket end)
  end

  def get_id(socket) do
    case get_all() |> Enum.find(nil, fn {_, s} -> s === socket end) do
      nil -> nil
      {id, _} -> id
    end
  end

  def add(conn) do
    GenServer.cast(__MODULE__, {:add, conn})
  end

  def remove(conn) do
    GenServer.cast(__MODULE__, {:remove, conn})
  end

  def create_id do
    %{hour: hour, minute: minute, second: second, microsecond: {ms, _}} = DateTime.utc_now()

    "#{hour}-#{minute}-#{second}-#{String.slice(to_string(ms), 0, 3)}"
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
    {:noreply, [{create_id(), conn} | state]}
  end

  @impl true
  def handle_cast({:remove, conn}, state) do
    {:noreply, Enum.filter(state, fn {_, s} -> s !== conn end)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :port, conn, _reason}, state) do
    remove(conn)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug(
      "Unexpected message in Connections: #{inspect(msg)}, is_port?: #{is_port(elem(msg, 3))}"
    )

    if is_port(elem(msg, 3)) do
      remove(elem(msg, 3))
    end

    {:noreply, state}
  end
end

# defmodule Connections do
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
