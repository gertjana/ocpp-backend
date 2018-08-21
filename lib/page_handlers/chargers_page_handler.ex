defmodule PageHandlers.Chargers do

  @moduledoc """
    Render the Chargers page
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

  defp build_body(_request) do
    {:ok, chargers} = GenServer.call(Chargepoints, :subscribers)
  	PageUtils.renderPage("chargers_page.html", "Chargers", [chargers: chargers])
  end
end
