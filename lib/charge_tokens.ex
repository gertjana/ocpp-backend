defmodule Chargetokens do
  use GenServer
  use Agent
  import Logger

  def start_link(_) do 
    {:ok, pid} = GenServer.start_link(__MODULE__, %{
      "01020304" => %{blocked: false, printed: "NL-GAS-1234567-X"},
      "01020305" => %{blocked: true, printed: "NL-GAS-1234568-X"},
      "01020306" => %{blocked: false, printed: "NL-GAS-1234569-X"}
      }, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def handle_call({:add, rfid, printed}, _from, chargetokens) do
    {:reply, :ok, Map.put(chargetokens, rfid,  
      %{blocked: false, printed: printed})}
  end

  def handle_call({:remove, rfid}, _from, chargetokens) do
    {:reply, :ok, Map.delete(chargetokens, rfid)}
  end

  def handle_call(:all, _from, chargetokens) do
    {:reply, {:ok, chargetokens}, chargetokens}
  end

  def handle_call({:block, rfid}, _from, chargetokens) do
    {:reply, :ok, put_in(chargetokens[rfid].blocked, true)}
  end

  def handle_call({:unblock, rfid}, _from, chargepoints) do
    {:reply, :ok, put_in(chargepoints[rfid].blocked, false)}
  end
end