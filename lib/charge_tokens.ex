defmodule Chargetokens do
  use GenServer
  use Agent
  import Logger

@moduledoc """
  Provides access to charge tokens
 """
 
   def start_link(_) do 
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def handle_call({:add, token, provider, description}, _from, _state) do
    token = %Model.Token{token: token, provider: provider, description: description}
    {:ok, inserted} = OcppBackendRepo.insert(token)
    {:reply, :ok, inserted}
  end

  def handle_call({:remove, token, provider}, _from, state) do
    {:ok, _} = OcppBackendRepo.delete(getToken(token, provider))
    {:reply, :ok, state}
  end

  def handle_call(:all, _from, state) do
    chargetokens = Model.Token |> OcppBackendRepo.all()
    {:reply, {:ok, chargetokens}, state}
  end

  def handle_call({:block, token, provider}, _from, _state) do
    {:ok, updated} = updateToken(token, provider, %{blocked: true})
    {:reply, :ok, updated}
  end

  def handle_call({:unblock, token, provider}, _from, _state) do
    {:ok, updated} = updateToken(token, provider, %{blocked: false})
    {:reply, :ok, updated}
  end

  defp updateToken(token, provider, changeset) do
    token = getToken(token, provider)
    changeset = Model.Token.changeset(token, changeset)
    OcppBackendRepo.update(changeset)
  end

  defp getToken(token, provider) do
    Model.Token |> OcppBackendRepo.get_by(token: token, provider: provider)
  end
end