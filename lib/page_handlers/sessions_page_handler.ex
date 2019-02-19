
defmodule PageHandlers.Sessions do

  @moduledoc """
    Render the sessions page
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
    {:ok, sessions} = Chargesessions.all(50, 0)
    PageUtils.renderPage("sessions_page.html", "Sessions", [sessions: sessions])
  end
end
