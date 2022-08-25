defmodule TcpTest do
  def test do
    path = "E:\\dummyCode\\golang\\pseudo-ftp\\Networking.mp4"

    # content = File.read!(path)

    # IO.puts("size: #{byte_size(content)}")

    st = File.stream!(path, [], 2048)
    f = File.open!("result.mp4", [:write])

    st
    |> Enum.map(fn x -> x end)
    |> Enum.each(fn x ->
      IO.binwrite(f, x)
    end)

    IO.puts("done")
    File.close(f)
  end
end
