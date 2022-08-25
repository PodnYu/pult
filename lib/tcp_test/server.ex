defmodule Server do
  require Logger

  @chunk_size 1024

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("user connected")

    conns = Connections.get() |> Enum.map(fn s -> "[#{get_socket_id(s)}]" end) |> Enum.join(", ")
    IO.puts("connected sockets: #{conns}")

    Connections.add(client)

    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} ->
        serve_ok(socket, line)

      {:error, reason} ->
        Logger.info("error: #{reason}")
    end
  end

  def serve_ok(socket, line) do
    line = String.trim(line)

    IO.puts("line: #{line}")

    follower = hd(Connections.get() |> Enum.filter(fn x -> x != socket end))

    case line do
      "s" ->
        :gen_tcp.send(follower, "s\n")
        serve(socket)

      "i" ->
        :inet.setopts(socket, packet: :raw)
        {:ok, data} = :gen_tcp.recv(socket, 4)
        <<size::little-32>> = data

        Logger.info("size: #{size}, chunk size: #{@chunk_size}")

        :gen_tcp.send(follower, data)

        handle_file(socket, size, follower)

        serve(socket)

      _ ->
        :gen_tcp.send(socket, "invalid command\n")
        serve(socket)
    end
  end

  def handle_file(socket, size, follower) do
    case size do
      x when x <= @chunk_size ->
        {:ok, content} = :gen_tcp.recv(socket, size)
        :gen_tcp.send(follower, content)
        IO.puts("done")

      _ ->
        {:ok, content} = :gen_tcp.recv(socket, @chunk_size)
        :gen_tcp.send(follower, content)
        handle_file(socket, size - @chunk_size, follower)
    end
  end

  def get_socket_id(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    addr = :inet.ntoa(addr)

    "#{addr}:#{port}"
  end
end
