defmodule TokenAuthorisation do
  use GenServer
  import Logger

  @moduledoc """
    Module that provides a very simple token authorization mechanism
 """
 

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end 

  def handle_call({:token, token}, _sender, state) do
    {:ok, tokens} = GenServer.call(Chargetokens, :all)
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