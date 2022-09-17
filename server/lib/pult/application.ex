defmodule Pult.Application do
  use Application
  alias Pult.Server
  alias Pult.Connections

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:pult, :port)
    IO.puts("port: #{port}")

    children = [
      {Task.Supervisor, name: Pult.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Server.accept(port) end},
        restart: :permanent,
        id: :acceptor
      ),
      Connections
    ]

    opts = [strategy: :one_for_one, name: Pult.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
