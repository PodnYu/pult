defmodule Pult.Dispatcher do
  require Logger
  alias Pult.Commands

  def dispatch(socket, line) do
    line = String.trim(line)

    Logger.debug("line: '#{line}'")

    [cmd | args] = String.split(line, ~r/\s+/)

    case cmd do
      "list_clients" ->
        Commands.ListClients.list_clients(socket)

      "make_screenshot" ->
        Commands.MakeScreenshot.make_screenshot(socket, Enum.join(args))

      "screenshot" ->
        Commands.Screenshot.screenshot(
          socket,
          Enum.join(args),
          Application.get_env(:pult, :chunk_size)
        )

      _ ->
        Logger.info("invalid command")
        Pult.Utils.send_not_ok_resp(socket, "invalid command")
    end
  end
end
