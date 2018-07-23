defmodule ChargerPageHandler do
  import Logger

  @moduledoc """
    Renders Page for a single charger
  """

  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
   req = :cowboy_req.reply(
      200,
      %{"content-type" => "text/html"},
      build_body(request),
      request
    )
    {:ok, req, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  def build_body(request) do
  	serial = :cowboy_req.binding(:serial, request)
  	{:ok, charger} = GenServer.call(Chargepoints, {:subscriber, serial})
    Utils.renderPage("charger_page.html", "Charger #{serial}", [
        charger: charger
      ])
  end
end
