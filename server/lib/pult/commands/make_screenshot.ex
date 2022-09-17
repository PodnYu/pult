defmodule Pult.Commands.MakeScreenshot do
  require Logger

  alias Pult.Connections
  alias Pult.Utils

  def make_screenshot(socket, receiver_id) do
    id = Connections.get_id(socket)

    case Connections.get_by_id(receiver_id) do
      nil ->
        msg = "no client with id: #{receiver_id}"
        Logger.debug(msg)
        Utils.send_not_ok_resp(socket, msg)

      receiver ->
        Utils.send_cmd(receiver, "make_screenshot #{id}")
    end
  end
end
