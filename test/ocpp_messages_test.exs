defmodule Ocpp.MessagesTest do
  use ExUnit.Case, async: true
  alias Ocpp.Messages, as: OcppMessages

  setup do
    genserver_pid = case Process.whereis(Ocpp.Messages) do
      nil ->
        {:ok, pid} = OcppMessages.start_link([])
        Process.register(pid, :occp_messages)
        pid
      pid -> pid
    end
    {:ok, pid: genserver_pid}
  end

  test "Authorize", %{pid: _pid} do
    state = %{serial: "09000099"}
    {{:text, reply}, _state} = GenServer.call(OcppMessages, {[2, "42", "Authorize", %{"idTag" => "01020304"}], state})
    check(reply, "42", ["idTagInfo"], [])
  end

  test "BootNotification" , %{pid: _pid} do
    state = %{serial: "09000099"}
    {{:text, reply}, _state} = GenServer.call(OcppMessages,
      {[2, "42", "BootNotification", %{"chargeBoxSerialNumber" => "GA0000001", "chargePointModel" => "GA", "chargePointVendor" => "AddictiveSoftware"}], state})
    check(reply, "42", ["currentTime", "interval", "status"], [])
  end

  test "DataTransfer" , %{pid: _pid} do
    state = %{serial: "09000099"}
    {{:text, reply}, _state} = GenServer.call(OcppMessages,
      {[2, "42", "DataTransfer", %{"vendorId" => "AddictiveSoftware", "messageId" => "MessageOne", "data" => "foo foo bar"}], state})
    check(reply, "42", ["status"], ["data"])
  end

  test "Heartbeat", %{pid: _pid} do
  	state = %{serial: "09000099"}
    {{:text, reply}, _state} = GenServer.call(OcppMessages, {[2, "42", "Heartbeat", %{}], state})
    check(reply, "42", ["currentTime"], [])
  end

  defp check(message, id, required_fields, optional_fields) do
    {:ok, obj} = JSX.decode(message)
    # Reponse from Central System should always start with a 3
    assert [3 | tail] = obj
    [answer_id | answer_fields] = tail
    # the Reponse Id should match the Request
    assert answer_id == id
    # Test that at least the required fields are present in the answer
    assert required_fields == (answer_fields |> hd |> Map.keys) -- optional_fields
  end
end
