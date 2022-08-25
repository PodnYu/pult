defmodule Pult.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = 4001

    children = [
      {Task.Supervisor, name: Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Server.accept(port) end}, restart: :permanent),
      Connections
    ]

    opts = [strategy: :one_for_one, name: TcpTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
