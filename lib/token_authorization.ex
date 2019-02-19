defmodule TokenAuthorisation do
  use GenServer
  import Logger

  @moduledoc """
    Module that provides a very simple token authorization mechanism
  """

  def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  # Client

  def authorize(id_tag) do
    GenServer.call(TokenAuthorisation, {:token, id_tag})
  end

  # Callbacks

  def handle_call({:token, token}, _sender, state) do
    {:ok, tokens} = Chargetokens.all
    authorised =
    case tokens
      |> Enum.filter(fn(t) -> t.token == token end)
      |> Enum.map(fn(t) -> t.blocked end) do
        []            -> "Invalid"
        [true | _]  -> "Blocked"
        [false | _] -> "Accepted"
    end
    {:reply, authorised, state}
  end
end
