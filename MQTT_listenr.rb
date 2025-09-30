require 'mqtt'
require 'json'  

# MQTT connection settings as variables

DEFAUL_MQTT_HOST = json.parse(File.read('config.json'))['mqtt']['host'] || 'localhost'
DEFAUL_MQTT_PORT = json.parse(File.read('config.json'))['mqtt']['port'] || 1883
DEFAUL_MQTT_TOPIC = json.parse(File.read('config.json'))['mqtt']['topic'] || 'test/#'

print "Enter MQTT broker host (default: #{DEFAUL_MQTT_HOST}): "
mqtt_host = gets.strip
mqtt_host = DEFAUL_MQTT_HOST if mqtt_host.empty?

print "Enter MQTT broker port (default: #{DEFAUL_MQTT_PORT}): "
mqtt_port_input = gets.strip
mqtt_port = mqtt_port_input.empty? ? DEFAUL_MQTT_PORT : mqtt_port_input.to_i

print "Enter MQTT topic to subscribe to (default: #{DEFAUL_MQTT_TOPIC}): "
mqtt_topic = gets.strip
mqtt_topic = DEFAUL_MQTT_TOPIC if mqtt_topic.empty?

alert_topic = 'gmc/alert#' # Topic to publish alerts to

WS558_euid = '24e124756c404098' # Unique identifier for the WS558 device


def listen_for_messages(host, port, topic)
  MQTT::Client.connect(host: host, port: port) do |client|
    puts "Connected to MQTT broker at #{host}:#{port}, subscribing to '#{topic}'"
    client.subscribe(topic)
    client.get do |received_topic, message|
      puts "Received message on topic '#{received_topic}': #{message}"

      if received_topic == alert_topic
        # Handle alert messages
        puts "ALERT: #{message}"
      end

    end
  end
end

def configure_WS558(host, port, alert_topic, alert_message)
  MQTT::Client.connect(host: host, port: port) do |client|
    client.publish(alert_topic, alert_message)
    puts "Published alert to topic '#{alert_topic}': #{alert_message}"
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