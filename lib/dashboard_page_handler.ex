
defmodule DashboardPageHandler do
 
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

  defp charger_rows() do 
    {:ok, chargers} = GenServer.call(Chargepoints, :subscribers)
    Enum.map(chargers, 
      fn {
        k,v} -> "  <tr>" 
            <>  "    <td>#{k}</td>"
            <>  "    <td>#{inspect(v.pid)}</td>"
            <>  "    <td>#{v.status}</td>"
            <>  "    <td>#{v.connected}</td>"
            <>  "    <td>#{v.last_seen}</td>"
            <>  "  </tr>"
      end)
  end

  defp token_rows() do
    {:ok, tokens} = GenServer.call(Chargetokens, :all)
    Enum.map(tokens, 
      fn {
        k,v} -> "  <tr>" 
            <>  "    <td>#{k}</td>"
            <>  "    <td>#{v.printed}</td>"
            <>  "    <td>#{v.blocked}</td>"
            <>  "  </tr>"
      end)    
  end

  defp session_rows() do
    {:ok, sessions} = GenServer.call(Chargesessions, :all)
    Enum.map(sessions, 
      fn {
        k,v} ->  "  <tr>"
             <>  "    <td>#{k}</td>" 
             <>  "    <td>#{v.serial}</td>" 
             <>  "    <td>#{v.idtag}</td>" 
             <>  "    <td>#{v.starttime}</td>" 
             <>  "    <td>#{v.endtime}</td>" 
             <>  "    <td>#{v.volume}</td>" 
             <>  "    <td>#{v.duration}</td>" 
             <>  "  </tr>" 
      end)
  end


  defp build_body(_request) do    
"""
<!DOCTYPE html> 
<html>
  <head>
    <title>Chargers</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width">
    <link href="/static/css/bootstrap.min.css" rel="stylesheet">
    <title>Chargers</title>
    <style>
      div.jumbotron {
        padding-left:20px;
      }
    </style>
  </head>

  <body>
    <div class="jumbotron">
      <h1>Charger Backend</h1> 
      <p>An OCPP 1.6 backend built in Elixir</p> 
    </div>          
    <div class="container">
      <div class="row">
        <div class="col">
          <div class="panel panel-default">
            <div class="panel-body">
              #{Enum.count(charger_rows())} Chargers online
            </div>
          </div>
        </div>
      </row> 
      <div class="row">
        <div class="col-md-8">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h3 class="panel-title">Chargers</h3>
            </div>
            <div class="panel-body">
                <table class="table">
                  <tr>
                    <th>Serial</th>
                    <th>PID</th>
                    <th>Status</th>
                    <th>Connected</th>
                    <th>Last seen</th>
                    #{charger_rows()}
                  </tr>
                </table>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h3 class="panel-title">Tokens</h3>
            </div>
            <div class="panel-body">
                <table class="table">
                  <tr>
                    <th>Rfid</th>
                    <th>Printed Number</th>
                    <th>Blocked</th>
                    #{token_rows()}
                  </tr>
                </table>
            </div>
          </div>
        </div>
      </div>  
      <div class="row">
        <div class="col-md-12">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h3 class="panel-title">Sessions</h3>
            </div>
            <div class="panel-body">
                <table class="table">
                  <tr>
                    <th>Transaction Id</th>
                    <th>Serial</th>
                    <th>Id Tag</th>
                    <th>Start Time</th>
                    <th>Stop Time</th>
                    <th>Volume</th>
                    <th>Duration</th>
                  </tr>
                  #{session_rows()}
                </table>
            </div>
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



      #   </div>
      # </div>
