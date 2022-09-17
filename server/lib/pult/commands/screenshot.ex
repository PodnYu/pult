defmodule Pult.Commands.Screenshot do
  require Logger
  alias Pult.Connections
  alias Pult.Utils

  def screenshot(socket, receiver_id, chunk_size \\ 1024) do
    receiver = Connections.get_by_id(receiver_id)

    :inet.setopts(socket, packet: :raw)
    {:ok, data} = :gen_tcp.recv(socket, 4)
    size = get_file_size(data)

    Logger.info("size: #{size}, chunk size: #{chunk_size}")

    Utils.send_cmd(receiver, "screenshot")
    :gen_tcp.send(receiver, data)

    proxy_file(socket, receiver, size, chunk_size)

    :inet.setopts(socket, packet: :line)
  end

  def get_file_size(data) do
    <<size::little-32>> = data
    size
  end

  def proxy_file(from, to, size, chunk_size) do
    case size do
      x when x <= chunk_size ->
        {:ok, content} = :gen_tcp.recv(from, size)
        :gen_tcp.send(to, content)
        Logger.debug("file done")

      _ ->
        {:ok, content} = :gen_tcp.recv(from, chunk_size)
        :gen_tcp.send(to, content)
        proxy_file(from, to, size - chunk_size, chunk_size)
    end
  end
end
