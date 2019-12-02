defmodule OcppKafka do
  @topic "ocpp_messages"

  def send_message(serial, occp_message) do
    KafkaEx.produce(@topic, serial, occp_message)
  end
end