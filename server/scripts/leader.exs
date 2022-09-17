# This scripts is used in conjunction with follower.exs to test 'make_screenshot' command.
# sends command to make a screenshot and outputs response(follower sends some plain text instead of png).
defmodule Leader do
  def run(host, port) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, packet: :line, active: false])
    IO.puts("connected")

    {id, addr} = get_client(socket)

    IO.puts("id: #{id}, addr: #{addr}")

    :gen_tcp.send(socket, "make_screenshot #{id}\n")
    {:ok, line} = :gen_tcp.recv(socket, 0)
    line = String.trim(line)

    IO.puts("got line: '#{line}'")

    get_data(socket)

    :gen_tcp.close(socket)
  end

  def clients(str) do
    cs = String.split(str, ~r/,/)

    cs
    |> Enum.map(fn x ->
      [id, addr] = String.split(x, ~r/ /)
      {id, addr}
    end)
  end

  def get_client(socket) do
    :gen_tcp.send(socket, "list_clients\n")

    {:ok, line} = :gen_tcp.recv(socket, 0)
    line = String.trim(line)

    ["ok", clients_str] = String.split(line, ~r/:/, parts: 2)

    clients = Leader.clients(clients_str)

    Enum.at(clients, 0)
  end

  def get_data(socket) do
    :inet.setopts(socket, packet: :raw)
    size = recv_size(socket)
    IO.puts("size: #{size}")

    chunk_size = 1024
    data = recv_data(socket, size, chunk_size)
    IO.puts("data: '#{data}'")

    :inet.setopts(socket, packet: :line)
  end

  def recv_size(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 4)
    <<size::little-32>> = data
    size
  end

  def recv_data(socket, size, chunk_size, output \\ "") do
    case size do
      x when x <= chunk_size ->
        {:ok, content} = :gen_tcp.recv(socket, size)
        output <> content

      _ ->
        {:ok, content} = :gen_tcp.recv(socket, chunk_size)
        recv_data(socket, size - chunk_size, chunk_size, output <> content)
    end
  end
end

Leader.run('localhost', 4001)
