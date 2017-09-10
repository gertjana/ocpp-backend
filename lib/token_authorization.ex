defmodule TokenAuthorisation do
  use GenServer
  import Logger

  def start_link(_) do
    info "Starting TokenAuthorisation module"
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end 

  defp tokens do
    %{
      "0102030405060708" => false,
      "0102030405060709" => true,
      "010203040506070A" => false
    }
  end

  def handle_call({:rfid, rfid}, _sender, state) do
    authorised = 
      case Map.get(tokens(),rfid) do
        blocked when not blocked -> "Accepted"
        blocked when blocked     -> "Blocked"
        nil                      -> "Invalid"
      end
    {:reply, authorised, state}
  end

end