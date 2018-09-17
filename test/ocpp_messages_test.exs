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

    test "BootNotification returns a correct response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "BootNotification", %{"chargeBoxSerialNumber" => "GA0000001", "chargePointModel" => "GA", "chargePointVendor" => "AddictiveSoftware"}], state})
      check_success(reply, id, ["currentTime", "interval", "status"], [])
    end

    test "DataTransfer returns a correct response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "DataTransfer", %{"vendorId" => "AddictiveSoftware", "messageId" => "MessageOne", "data" => "foo foo bar"}], state})
      check_error(reply, id)
    end

    test "DiagnosticsStatusNotification returns a correct response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "DiagnosticsStatusNotification", %{"status" => []}], state})
      check_success(reply, id, [], [])
    end

    test "FirmwareStatusNotification returns a correct response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "FirmwareStatusNotification", %{"status" => []}], state})
      check_success(reply, id, [], [])
    end

    test "Heartbeat returns a correct response" do
      id = random_id()
    	state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "Heartbeat", %{}], state})
      check_success(reply, id, ["currentTime"], [])
    end

    test "MeterValues returns an error response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "MeterValues", %{"connectorId" => 0, "transactionId" => random_id(), "meterValue" => []}], state})
      check_success(reply, id, [], [])
    end

    test "StatusNotification returns a correct response" do
      id = random_id()
      state = %{serial: "09000099"}
      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StatusNotification", %{"status" => "Available", "connectorId" => 0, "errorCode" => ""}], state})
     check_success(reply, id, [], [])
     end

    test "StartTransaction and StopTransaction return a correct response" do
      id = random_id()
      id_token = "01020304"

      state = %{serial: "09000099"}

      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StartTransaction", %{"connectorId" => 0, "transactionId" => id, "idTag" => id_token, "meterStart" => random_id(), "timestamp" => Utils.datetime_as_string()}], state})
      check_success(reply, id, ["idTagInfo", "transactionId"], [])

      state_after_start = %{serial: "09000099", currentTransaction: %{transaction_id: id, start: 2000, timestamp: Utils.datetime_as_string(), idTag: id_token}}

      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StopTransaction", %{"idTag" => id_token, "transactionId" => id, "meterStop" => 2145, "timestamp" => Utils.datetime_as_string(10)}], state_after_start})
      check_success(reply, id, [], ["idTagInfo"])
    end

    test "StopTransaction should respond with an error when a transaction hasn't started yet" do
      id_token = "01020304"
      id = random_id()
      state = %{serial: "09000099"}

       {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StopTransaction", %{"idTag" => id_token,
           "transactionId" => id, "meterStop" => 2145, "timestamp" => Utils.datetime_as_string(10)}], state})
      check_error(reply, id)
    end

    test "StartTransaction should respond with an error when a transaction has already started" do
      id_token = "01020304"
      id = random_id()
      state_after_start = %{serial: "09000099", currentTransaction: %{transaction_id: id, start: 2000, timestamp: Utils.datetime_as_string(), idTag: id_token}}

      {{:text, reply}, _state} = GenServer.call(OcppMessages,
        {[2, id, "StartTransaction", %{"connectorId" => 0, "transactionId" => id, "idTag" => id_token, "meterStart" => random_id(), "timestamp" => Utils.datetime_as_string()}], state_after_start})
      check_error(reply, id)      
    end

    defp check_success(message, id, required_fields, optional_fields) do
      {:ok, obj} = JSX.decode(message)
      assert [3 | tail] = obj                     # Reponse from Central System should always start with a 3
      [answer_id | answer_fields] = tail          # the Reponse Id should match the Request Id
      assert answer_id == id
      if (length(required_fields) > 0) do         # Test that at least the required fields are present in the response
        assert required_fields == (answer_fields |> hd |> Map.keys) -- optional_fields
      end
    end

    defp check_error(response, error_code \\ "", error_message \\ "") do
      {:ok, obj} = JSX.decode(response)
      # Error Reponse from Central System should always start with a 4
      [four|[resp_error_code|[resp_error_message|_]]] = obj
      assert 4 == four
      if error_code != "" do
        assert error_code == resp_error_code
      end
      if error_message != "" do
        assert error_message == resp_error_message
      end
    end

    defp random_id, do: Integer.to_string(:rand.uniform(10_000))
  end
end
