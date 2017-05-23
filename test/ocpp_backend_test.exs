defmodule OcppBackendTest do
  use ExUnit.Case

  defp m(name, id) do
    case name do 
      "BootNotificationReq"  -> "[2, \"#{id}\", \"BootNotification\", {\"chargeBoxSerialNumber\": \"04000123\", \"chargePointModel\":\"Lolo4\"}]"
      "HeartbeatReq" -> "[2, \"#{id}\", \"Heartbeat\"]"
      "AuthorizeReq" -> "[2, \"#{id}\", \"Authorize\", {\"idToken\":\"0102030405060708\"}]"
      "AuthorizeConf" -> "[3, \"#{id}\", {\"idTagInfo\" : {\"status\":\"Accepted\", \"idToken\":\"0102030405060708\"}}]"
      "StartTransactionReq" -> "[2, \"#{id}\", \"StartTransaction\", {\"connectorId\":\"0\", \"idTag\":\"0102030405060708\", \"meterStart\":\"0\", \"timestamp\":\"#{now}\"}]"
      "StopTransactionReq" -> "[2, \"#{id}\", \"StopTransaction\", {\"idTag\":\"0102030405060708\", \"meterStop\":\"0\", \"timestamp\":\"#{now}\"}]"
    end
  end

  defp now do
    DateTime.to_string(DateTime.utc_now())
  end 

  test "BootNotification" do
    id = UUID.uuid1()

    {:reply, {:text, reply}, _, _} = WebsocketHandler.websocket_handle({:text, m("BootNotificationReq",id)}, :cowboy_req, %{})
    {:ok, received } = JSEX.decode(reply)

    assert 3 == hd(received)
    assert id == hd(tl(received))
    assert "Accepted" == Map.get(hd(tl(tl(received))),"status")
    assert 300 == Map.get(hd(tl(tl(received))),"heartbeatInterval")
    assert Map.has_key?(hd(tl(tl(received))), "currentTime")
  end

  test "Heartbeat" do
    id = UUID.uuid1()

    {:reply, {:text, reply}, _, _} = WebsocketHandler.websocket_handle({:text, m("HeartbeatReq",id)}, :cowboy_req, %{})
    {:ok, received } = JSEX.decode(reply)

    assert 3 == hd(received)
    assert id == hd(tl(received))
    assert Map.has_key?(hd(tl(tl(received))), "currentTime")
  end

  test "Authorize" do
    id = UUID.uuid1()

    {:reply, {:text, reply}, _, _} = WebsocketHandler.websocket_handle({:text, m("AuthorizeReq",id)}, :cowboy_req, %{})

    assert JSEX.decode(m("AuthorizeConf", id)) == JSEX.decode(reply)
  end

  test "StartTransaction" do
    id = UUID.uuid1()
    state = %{serial: "0400030", id: 0}

    {:reply, {:text, reply}, _, _} = WebsocketHandler.websocket_handle({:text, m("StartTransactionReq",id)}, :cowboy_req, state)
    {:ok, received } = JSEX.decode(reply)

    assert 3 == hd(received)
    assert id == hd(tl(received))
    assert "0400030_1" == Map.get(hd(tl(tl(received))), "transactionId")

    idTagInfo = Map.get(hd(tl(tl(received))), "idTagInfo")
    assert Map.has_key?(idTagInfo, "idToken")
    assert "Accepted" == Map.get(idTagInfo, "status")
  end

  test "StopTransaction" do
    id = UUID.uuid1()

    {:reply, {:text, reply}, _, _} = WebsocketHandler.websocket_handle({:text, m("StopTransactionReq",id)}, :cowboy_req, %{})
    {:ok, received } = JSEX.decode(reply)

    assert 3 == hd(received)
    assert id == hd(tl(received))

    idTagInfo = Map.get(hd(tl(tl(received))), "idTagInfo")
    assert Map.has_key?(idTagInfo, "idToken")
    assert "Accepted" == Map.get(idTagInfo, "status")
  end

end
