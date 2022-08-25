defmodule Test do
  def get_data(file \\ "test.txt") do
    data = File.read!(file)
    {byte_size(data), data}
  end

  def to_int32(x) do
    <<x::little-32>>
  end

  def recv_file(socket, file, size, chunk_size) do
    case size do
      x when x <= chunk_size ->
        {:ok, content} = :gen_tcp.recv(socket, size)
        # :gen_tcp.send(follower, content)
        IO.binwrite(file, content)
        IO.puts("done")

      _ ->
        {:ok, content} = :gen_tcp.recv(socket, chunk_size)
        # :gen_tcp.send(file, content)
        IO.binwrite(file, content)
        recv_file(socket, file, size - chunk_size, chunk_size)
    end
  end

  def recv(socket, size, chunk_size, output \\ "") do
    case size do
      x when x <= chunk_size ->
        {:ok, content} = :gen_tcp.recv(socket, size)
        output <> content

      _ ->
        {:ok, content} = :gen_tcp.recv(socket, chunk_size)
        recv_file(socket, size - chunk_size, chunk_size, output <> content)
    end
  end
end

data = "hello"
size = String.length(data)

{:ok, follower} = :gen_tcp.connect('localhost', 4001, [:binary, active: false])
{:ok, leader} = :gen_tcp.connect('localhost', 4001, [:binary, active: false])

IO.puts("connected")

:gen_tcp.send(leader, "s\n")

{:ok, line} = :gen_tcp.recv(follower, 0)
line = String.trim(line)

if line !== "s" do
  :gen_tcp.close(leader)
  :gen_tcp.close(follower)
  exit(:shutdown)
end

IO.puts("size: #{size}")
IO.puts("data: '#{data}'")

:gen_tcp.send(follower, "i\n")
:ok = :gen_tcp.send(follower, <<size::little-32>>)
:gen_tcp.send(follower, data)

{:ok, data} = :gen_tcp.recv(leader, 4)

chunk_size = 1024

<<size::little-32>> = data

IO.puts("size: #{size}")

data = Test.recv(leader, size, chunk_size)
IO.puts("data: '#{data}'")

if data == data do
  IO.puts("OK")
end

:gen_tcp.close(leader)
:gen_tcp.close(follower)
