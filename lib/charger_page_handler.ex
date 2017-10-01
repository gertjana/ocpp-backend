
defmodule ChargerPageHandler do
 
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
      [ {"content-type", "text/html"} ],

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

  defp build_body(_request) do
    {:ok, chargers} = GenServer.call(Chargepoints, :subscribers)
    table = Enum.map(chargers, fn {k,v} -> "<tr><td>#{k}</td><td>#{inspect(v.pid)}</td><td>#{v.status}</td></tr>" end)


"""
<!DOCTYPE html> 
<html>
    <head>
        <title>Elixir OCPP Test client</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width">
        <link href="/static/css/bootstrap.min.css" rel="stylesheet">
        <title>Chargers</title>
        <style>
          td {
            padding-right:10px;
          }
        </style>
    </head>
    <body>
      <div class="panel panel-default">
        <div class="panel-body">
          <div class="page-header"><h1>OCPP 1.6 Elixir Backend</h1></div>
          <div class="panel panel-default">
            <div class="panel-body">
                  #{Enum.count(chargers)} Chargers online
            </div>
          </div>

          <div class="panel panel-default">
            <div class="panel-heading">
              <h3 class="panel-title">Chargers</h3>
            </div>
            <div class="panel-body">
                <table>
                  <tr>
                    <th>Serial</th>
                    <th>PID</th>
                    <th>Status</th>
                    #{table}
                  </tr>
                </table>
            </div>
          </div>
        </div>
      </div>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="/static/js/bootstrap.min.js"></script>    
    </body>
</html>
"""
  end
end