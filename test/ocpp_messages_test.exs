defmodule Ocpp.MessagesTest do
  use ExUnit.Case, async: true
  alias Ocpp.Messages, as: OcppMessages
  alias Model.Session, as: Session
  import Mock

  describe "The Central System should respond to messages as specified in the OCPP 1.6 Version 2 specification" do

    test "Authorize" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages, {[2, id, "Authorize", %{"idTag" => "01020304"}], state})
      check_success(reply, id, ["idTagInfo"], [])
    end

    test "BootNotification" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "BootNotification", %{"chargeBoxSerialNumber" => "GA0000001", "chargePointModel" => "GA", "chargePointVendor" => "AddictiveSoftware"}], state})
      check_success(reply, id, ["currentTime", "interval", "status"], [])
    end

    test "DataTransfer" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "DataTransfer", %{"vendorId" => "AddictiveSoftware", "messageId" => "MessageOne", "data" => "foo foo bar"}], state})
      check_success(reply, id, ["status"], ["data"])
    end

    test "DiagnosticsStatusNotification" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "DiagnosticsStatusNotification", %{"status" => []}], state})
      check_success(reply, id, [], [])
    end

  #[2, id, "FirmwareStatusNotification", %{"status" => _firmwareStatus}]
    test "FirmwareStatusNotification" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "FirmwareStatusNotification", %{"status" => []}], state})
      check_success(reply, id, [], [])
    end

    test "Heartbeat" do
      id = random_id()
    	state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "Heartbeat", %{}], state})
      check_success(reply, id, ["currentTime"], [])
    end

    test "MeterValues" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "MeterValues", %{"connector_id" => 0, "transaction_id" => random_id(), "meterValue" => []}], state})
      check_error(reply)
    end

    test "StatusNotification" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StatusNotification", %{"status" => "Available", "connectorId" => 0, "errorCode" => ""}], state})
     check_success(reply, id, [], [])
     end

    test "StartTransaction" do
      id = random_id()
      id_token = "01020304"
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StartTransaction", %{"connectorId" => 0, "transactionId" => random_id(), "idTag" => id_token, "meterStart" => random_id(), "timestamp" => Utils.datetime_as_string()}], state})
      check_success(reply, id, ["idTagInfo", "transactionId"], [])
    end

    # test "StopTransaction" do
    #   id_token = "01020304"
    #   id = random_id()
    #   state = %{serial: "09000099", currentTransaction: %{id: id, start: 2000, timestamp: Utils.datetime_as_string(), idTag: id_token}}
    #
    #   with_mock Chargesessions,
    #    [get_session: fn(id) -> %Session{connector_id: O, transaction_id: id, serial: state.serial, token: id_token, start_time: Timex.now()} end] do
    #       {{:text, reply}, _state} = GenServer.call(OcppMessages,
    #         {[2, id, "StopTransaction", %{"idTag" => id_token,
    #            "transactionId" => id, "meterStop" => 2145, "timestamp" => Utils.datetime_as_string(10)}], state})
    #       check_success(reply, id, [], ["idTagInfo"])
    #   end
    # end

    defp check_success(message, id, required_fields, optional_fields) do
      {:ok, obj} = JSX.decode(message)
      # Reponse from Central System should always start with a 3
      assert [3 | tail] = obj
      [answer_id | answer_fields] = tail
      # the Reponse Id should match the Request Id
      assert answer_id == id
      # Test that at least the required fields are present in the response
      if (length(required_fields) > 0) do
        assert required_fields == (answer_fields |> hd |> Map.keys) -- optional_fields
      end
    end

    defp check_error(message) do
      {:ok, obj} = JSX.decode(message)
      # Error Reponse from Central System should always start with a 4
      assert [4 | tail] = obj
    end

    defp random_id, do: Integer.to_string(:rand.uniform(10_000))
  end
end
