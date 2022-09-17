# this script connects to the server, sends command to make a screenshot
# and saves the screenshot to the given file
# Used to test the app manually
defmodule Client do
  def run(host, port, output_file \\ "result.png") do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, packet: :line, active: false])
    IO.puts("connected")

    {id, addr} = get_client(socket)

    IO.puts("id: #{id}, addr: #{addr}")

    :gen_tcp.send(socket, "make_screenshot #{id}\n")
    :gen_tcp.recv(socket, 0)

    :inet.setopts(socket, packet: :raw)
    {:ok, data} = :gen_tcp.recv(socket, 4)

    chunk_size = 1024

    <<size::little-32>> = data

    IO.puts("size: #{:erlang.float_to_binary(size / 1024, decimals: 2)} Kb")

    file = File.open!(output_file, [:write])

    recv_file(socket, file, size, chunk_size)

    File.close(file)

    :gen_tcp.close(socket)
  end

  def get_client(socket) do
    :gen_tcp.send(socket, "list_clients\n")

    {:ok, line} = :gen_tcp.recv(socket, 0)
    line = String.trim(line)

    ["ok", clients_str] = String.split(line, ~r/:/, parts: 2)

    cs = clients(clients_str)
    Enum.at(cs, 0)
  end

  def recv_file(socket, file, size, chunk_size) do
    case size do
      x when x <= chunk_size ->
        {:ok, content} = :gen_tcp.recv(socket, size)
        IO.binwrite(file, content)

      _ ->
        {:ok, content} = :gen_tcp.recv(socket, chunk_size)
        IO.binwrite(file, content)
        recv_file(socket, file, size - chunk_size, chunk_size)
    end
  end

  def clients(str) do
    cs = String.split(str, ~r/,/)

    cs
    |> Enum.map(fn x ->
      [id, addr] = String.split(x, ~r/ /)
      {id, addr}
    end)
  end
end

Client.run('localhost', 4001, "result.png")
