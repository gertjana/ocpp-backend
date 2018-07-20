
defmodule DashboardPageHandler do
 
@moduledoc """
  Render the dashboard (landing page)
 """
 
  def init(req, state) do
    handle(req, state)
  end


  def handle(request, state) do
    # construct a reply, using the cowboy_req:reply/4 function.
    #
    # reply/4 takes three arguments:
    #   * The HTTP response status (200, 404, etc.)
    #   * A list of 2-tuples representing headers
    #   * The body of the response
    #   * The original request
    req = :cowboy_req.reply(

      # status code
      200,

      # headers
      [{"content-type", "text/html"}],

      # body of reply.
      build_body(request),

      # original request
      request
    )

    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, req, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  defp online_chargers() do
    {:ok, chargers} = GenServer.call(Chargepoints, :subscribers)
    chargers 
      |> Enum.filter(fn x -> x.status != "Offline" end)
      |> Enum.count      
  end

  defp chargers() do 
    {:ok, chargers} = GenServer.call(Chargepoints, :subscribers)
    chargers
  end

  defp tokens() do
    {:ok, tokens} = GenServer.call(Chargetokens, :all)
    tokens
  end

  defp sessions() do
    {:ok, sessions} = GenServer.call(Chargesessions, :all)
    sessions
  end

  def build_body(_request) do  
    Utils.renderPage("dashboard.html", "Dashboard", [
        onlineChargers: online_chargers(),
        chargers: chargers(),
        tokens: tokens(),
        sessions: sessions()
      ])
  end

end



