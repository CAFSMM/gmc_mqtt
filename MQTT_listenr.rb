require 'mqtt'
require 'json'
require File.dirname(__FILE__) + '/tools/binaryTools.rb'

system("clear") || system("cls")

# MQTT connection settings as variables
config = JSON.parse(File.read('./configs.json'))

DEFAUL_MQTT_HOST = config['mqtt']['host'] || 'localhost'
DEFAUL_MQTT_PORT = config['mqtt']['port'] || 1883
DEFAUL_MQTT_TOPIC = config['mqtt']['topic'] || 'gmc/#'

puts "=== MQTT Listener & WS558 Configurator ==="
puts "Configure your MQTT broker settings below."
puts "Press Enter to use the default value shown in parentheses."
puts "\nCurrent Configuration:"
puts "-------------------------"
puts "MQTT Host: #{DEFAUL_MQTT_HOST}"
puts "MQTT Port: #{DEFAUL_MQTT_PORT}"
puts "MQTT Topic: #{DEFAUL_MQTT_TOPIC}"
puts "-------------------------"
print "Use this configuration? (Y/n): "

use_default = gets.strip.downcase
if use_default == 'n'
  print "Enter MQTT broker host: "
  mqtt_host = gets.strip

  print "Enter MQTT broker port: "
  mqtt_port = gets.strip.to_i

  print "Enter MQTT topic to subscribe to: "
  mqtt_topic = gets.strip
else
  mqtt_host = DEFAUL_MQTT_HOST
  mqtt_port = DEFAUL_MQTT_PORT
  mqtt_topic = DEFAUL_MQTT_TOPIC
end

WS558_euid = '24e124756c404098' # Unique identifier for the WS558 device


def listen_for_messages(host, port, topic)
  MQTT::Client.connect(host: host, port: port) do |client|
    puts "Connected to MQTT broker at #{host}:#{port}, subscribing to '#{topic}'"
    client.subscribe(topic)
    client.get do |received_topic, message|
      #puts "Received message on topic '#{received_topic}': #{message}"
      
      if message.strip.downcase == "exit"
        return "exit"
      end

      if received_topic.include?("alert")
        check_alert(host, port, JSON.parse(message)) rescue puts "Invalid JSON in alert message"
      end

    end
  end
end

def check_alert(host, port, json_payload)
  puts "Processing alert payload: #{json_payload}"
  if json_payload && json_payload["button"] == 1
    puts "Alert button pressed! Sending command to WS558..."
    data_payload = "08" #message header
    data_payload.concat(binary_to_hex("1000 0000 1000 0000")) #turn on 1#
    puts "Data payload to send: #{hex_to_base64(data_payload)} (hex: #{data_payload})"
      send_json_message(
        host,
        port,
        "gmc/downlink/#{WS558_euid}",
        JSON.generate(
          {
            "confirmed" => true,
            "fPort" => 85,
            "data" => hex_to_base64(data_payload)
          }
        )
      )
  end

  if json_payload && json_payload["button"] == 2
    puts "Alert button released! Sending command to WS558..."
    data_payload = "08" #message header
    data_payload.concat(binary_to_hex("1111 1111 0000 0000")) #turn ALL off
    puts "Data payload to send: #{hex_to_base64(data_payload)} (hex: #{data_payload})"
      send_json_message(
        host,
        port,
        "gmc/downlink/#{WS558_euid}",
        JSON.generate(
          {
            "confirmed" => true,
            "fPort" => 85,
            "data" => hex_to_base64(data_payload)
          }
        )
      )
  end

  if json_payload && json_payload["button"] == 3 #double press
    puts "Alert button released! Sending command to WS558..."
    data_payload = "08" #message header
    data_payload.concat(binary_to_hex("0100 0000 0100 0000")) #turn ALL off
    puts "Data payload to send: #{hex_to_base64(data_payload)} (hex: #{data_payload})"
      send_json_message(
        host,
        port,
        "gmc/downlink/#{WS558_euid}",
        JSON.generate(
          {
            "confirmed" => true,
            "fPort" => 85,
            "data" => hex_to_base64(data_payload)
          }
        )
      )
  end
end

def configure_WS558(host, port, ws558_euid, json_payload)
  MQTT::Client.connect(host: host, port: port) do |client|
    client.publish("gmc/downlink/#{ws558_euid}", json_payload)
    puts "Published alert to topic 'gmc/downlink/#{ws558_euid}': #{json_payload}"
  end
end

def send_json_message(host, port, topic, payload)
  puts "Connecting to MQTT broker at #{host}:#{port} to send message..."
  puts "Payload: #{payload}"
  MQTT::Client.connect(host: host, port: port) do |client|
    client.publish(topic, payload)
    puts "Sent JSON message to topic '#{topic}': #{payload}"
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