defmodule ChargerPageHandler do
 
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
   req = :cowboy_req.reply(
      200,
      [ {"content-type", "text/html"} ],
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
  	charger = GenServer.call(Chargepoints, {:get, serial})
    Utils.renderPage("charger.html", "Dashboard", [
        charger: charger,
      ])
  end
end
  	
  	
