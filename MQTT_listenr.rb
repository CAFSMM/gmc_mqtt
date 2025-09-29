require 'mqtt'
require 'json'  

# MQTT connection settings as variables
mqtt_host = 'localhost'   # IP address of the MQTT broker
mqtt_port = 1883          # Port of the MQTT broker
mqtt_topic = 'test/#' # Topic to subscribe to

def listen_for_messages(host, port, topic)
  MQTT::Client.connect(host: host, port: port) do |client|
    puts "Connected to MQTT broker at #{host}:#{port}, subscribing to '#{topic}'"
    client.subscribe(topic)
    client.get do |received_topic, message|
      puts "Received message on topic '#{received_topic}': #{message}"
      return message
    end
  end
end

def send_json_message(host, port, topic, payload)
  json_message = payload.to_json
  MQTT::Client.connect(host: host, port: port) do |client|
    client.publish(topic, json_message)
    puts "Sent JSON message to topic '#{topic}': #{json_message}"
  end
end

while true
  if listen_for_messages(mqtt_host, mqtt_port, mqtt_topic) == "exit"
    puts "Exit command received. Terminating listener."
    break
  end
end

# Example usage:
# send_json_message(mqtt_host, mqtt_port, mqtt_topic, { key: "value", foo: "bar" })