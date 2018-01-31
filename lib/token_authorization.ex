defmodule TokenAuthorisation do
  use GenServer
  import Logger

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end 

  def handle_call({:rfid, rfid}, _sender, state) do
    {:ok, tokens} = GenServer.call(Chargetokens, :all)
    authorised = 
      case Map.get(tokens,rfid) do
        blocked when not blocked -> "Accepted"
        blocked when blocked     -> "Blocked"
        nil                      -> "Invalid"
      end
    {:reply, authorised, state}
  end

end