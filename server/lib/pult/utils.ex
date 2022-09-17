defmodule Pult.Utils do
  def send_cmd(socket, cmd) do
    :gen_tcp.send(socket, "#{cmd}\n")
  end

  def send_resp(socket, ok?, resp) do
    prefix = if ok?, do: "ok", else: "nok"
    :gen_tcp.send(socket, "#{prefix}:#{resp}\n")
  end

  def send_ok_resp(socket, resp) do
    send_resp(socket, true, resp)
  end

  def send_not_ok_resp(socket, resp) do
    send_resp(socket, false, resp)
  end
end
