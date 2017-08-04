
defmodule DynamicPageHandler do
  @moduledoc """
  A cowboy handler for serving a single dynamic wepbage. No templates are used; the
  HTML is all generated within the handler.
  """

  @doc """
  inititalize a plain HTTP handler.  See the documentation here:
      http://ninenines.eu/docs/en/cowboy/1.0/manual/cowboy_http_handler/

  All cowboy HTTP handlers require an init() function, identifies which
  type of handler this is and returns an initial state (if the handler
  maintains state).  In a plain http handler, you just return a
  3-tuple with :ok.  We don't need to track a  state in this handler, so
  we're returning the atom :no_state.
  """
  def init(req, state) do
    handle(req, state)
  end

  @doc """
  Handle a single HTTP request.

  In a cowboy handler, the handle/2 function does the work. It should return
  a 3-tuple with :ok, a request object (containing the reply), and the current
  state.
  """
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


  @doc """
  Do any cleanup necessary for the termination of this handler.

  Usually you don't do much with this.  If things are breaking,
  try uncommenting the output lines here to get some more info on what's happening.
  """
  def terminate(_reason, _request, _state) do
    #IO.puts("Terminating for reason: #{inspect(reason)}")
    #IO.puts("Terminating after request: #{inspect(request)}")
    #IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end


  @doc """
  Assemble the body of a response in HTML.
  """
  def build_body(_request) do
"""
<!DOCTYPE html> 
<html>
    <head>
        <title>Elixir OCPP Test client</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width">
    </head>
    <body>
       
        <div>
            serial:<input type="text" id="serial" value="04000123"/>
        </div>
        <div> 
          <select id="messageSelect" onchange="selectMessage();">
            <option value=''></option>
            <option value='[2, "42", "BootNotification", {"chargeBoxSerialNumber": "04000123", "chargePointModel":"Lolo4"}]'>BootNotification</option>
            <option value='[2, "42", "Heartbeat"]'>Heartbeat</option>
            <option value='[2, "42", "Authorize", {"idToken":"0102030405060708"}]'>Authorize</option>
            <option value='[2, "42", "StartTransaction", {"connectorId":"0", "idTag":"0102030405060708", "meterStart": 2000, "timestamp":"#{Utils.time_as_string}"}]'>StartTransaction</option>
            <option value='[2, "42", "StopTransaction", {"idTag":"0102030405060708", "meterStop": 2140, "timestamp":"#{Utils.time_as_string}"}]'>StopTransaction</option>
          </select>
        </div>
        <div>
            message:<input size=120 type="text" id="messageinput"/>
        </div>
        <div>
            <button type="button" onclick="openSocket();" >Open</button>
            <button type="button" onclick="send();" >Send</button>
            <button type="button" onclick="closeSocket();" >Close</button>
        </div>
        <div id="messages"></div>
       
        <!-- Script to utilise the WebSocket -->
        <script type="text/javascript">
                       
            var webSocket;
            var messages = document.getElementById("messages");
           
           
            function openSocket(){
                // Ensures only one connection is open at a time
                if(webSocket !== undefined && webSocket.readyState !== WebSocket.CLOSED){
                   writeResponse("WebSocket is already opened.");
                    return;
                }
                serial = document.getElementById("serial").value;
                // Create a new instance of the websocket
                webSocket = new WebSocket("ws://localhost:8080/ocppws/"+serial, ["ocpp16", "ocpp17"]);
                 
                /**
                 * Binds functions to the listeners for the websocket.
                 */
                webSocket.onopen = function(event){
                    // For reasons I can't determine, onopen gets called twice
                    // and the first time event.data is undefined.
                    // Leave a comment if you know the answer.
                    if(event.data === undefined)
                        return;
                    writeResponse("Connection opened");
                    writeResponse(event.data);
                };
 
                webSocket.onmessage = function(event){
                    writeResponse(event.data);
                };
 
                webSocket.onclose = function(event){
                    writeResponse("Connection closed");
                };
            }
           
            /**
             * Sends the value of the text input to the server
             */
            function send(){
                var text = document.getElementById("messageinput").value;
                if (text == '') return;
                writeRequest(text);
                webSocket.send(text);
            }
           
            function closeSocket(){
                webSocket.close();
            }
 
            function writeRequest(text){
                messages.innerHTML += "<br/>REQ:" + text;
            }

            function writeResponse(text){
                messages.innerHTML += "<br/>RES:" + text;
            }
           

            function selectMessage() {
              document.getElementById("messageinput").value = document.getElementById("messageSelect").value;
            }
        </script>
       
    </body>
</html>
"""
  end
end
