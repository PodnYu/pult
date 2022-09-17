defmodule Pult.Server do
  require Logger
  alias Pult.Connections

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("user connected, #{inspect(client)}")

    Connections.add(client)

    {:ok, pid} = Task.Supervisor.start_child(Pult.Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} ->
        Pult.Dispatcher.dispatch(socket, line)
        serve(socket)

      {:error, reason} ->
        Logger.info("error: #{reason}, #{inspect(socket)}")
    end
  end
end
