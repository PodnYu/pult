# This script is used in conjunction with leader.exs
# It receives the 'make_screenshot' command and sends some plain text as response
defmodule Follower do
  def run(host, port) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, packet: :raw, active: false])
    IO.puts("connected")

    {:ok, line} = :gen_tcp.recv(socket, 0)
    line = String.trim(line)

    [cmd, receiver_id] = String.split(line, ~r/\s+/)

    if cmd !== "make_screenshot" do
      :gen_tcp.close(socket)
      exit(:shutdown)
    end

    data = "hello"
    size = String.length(data)

    IO.puts("size: #{size}")
    IO.puts("data: '#{data}'")

    :gen_tcp.send(socket, "screenshot #{receiver_id}\n")

    :ok = :gen_tcp.send(socket, to_int32(size))

    :gen_tcp.send(socket, data)

    :gen_tcp.close(socket)
  end

  def to_int32(x) do
    <<x::little-32>>
  end
end

Follower.run('localhost', 4001)
