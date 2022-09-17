defmodule Pult.Commands.ListClients do
  require Logger

  alias Pult.Connections
  alias Pult.Utils

  def list_clients(socket) do
    conns =
      Connections.get_all_except(socket)
      |> format_connections_list()

    Logger.debug("connections: #{conns}")

    Utils.send_ok_resp(socket, conns)
  end

  def format_connections_list(conns) do
    conns
    |> Enum.map(fn {id, s} -> "#{id} #{get_addr(s)}" end)
    |> Enum.join(",")
  end

  def get_addr(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    addr = :inet.ntoa(addr)

    "#{addr}:#{port}"
  end
end
