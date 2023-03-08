#!/bin/bash
#
# driver.sh
# DESCRIPION
# This script implements the functions of the driver system for the bash MQTT train intercomm system
# The script subscribes to a number of MQTT topics and responds if a message is received. Messages received are logged to a
# log file which is truncated to a configureable maximum number of lines.
#
# The main messages which are processed:
#
# 1. Apply brake messages from carriages.
# The brakes set to ON when a message is received. After a configurable period the brakes are restored to OFF. MQTT are posted when
# messages brakes are turned OFF or ON
#

brake_duration=10
log_file_maxlen=20
mqtt_host="${MQTT_HOST:-localhost}" # Set mqtt_host based on environment variable. Default to localhost
driver_message_prompt="Enter message for carriages: "

temp_file=/tmp/$$temp.txt

#
# Usage: log_message message
# Write a message to the log file. Keep the log file truncated
# to log_file_maxlen lines.
#
log_file="./driver.log"
log_message() {
    echo $(date +"%H:%M:%S") $* >>$log_file
    # Crop log file to log_file_maxlen lines max
    tail -n $log_file_maxlen $log_file >$temp_file
    mv $temp_file $log_file
}

#
# Usage: brake_on carriage
# Turn brakes ON in carriage and log a message
#
brake_on() {
    log_message "Brakes ON in carriage $1"
    mosquitto_pub -h $mqtt_host -t "/driver/$1/brake" -m "ON"
    echo "carriage$1: ON" >dash-carriage$1
}

#
# Usage: brake_off carriage
# Turn brakes OFF in carriage and log a message
#
brake_off() {
    log_message "Brakes OFF in carriage $1"
    mosquitto_pub -h $mqtt_host -t "/driver/$1/brake" -m "OFF"
    echo "carriage$1: OFF" >dash-carriage$1
}

#
# Usage: apply_brake carriage
# Turn the brake ON in carriage, wait the configured number of seconds and turn the brake OFF again
#
apply_brake() {
    brake_on $1
    sleep $brake_duration
    brake_off $1
}

# Ensure brakes are off
brake_off 1
brake_off 2

# Subscribe to message feed for brake activations
mosquitto_sub -v -h $mqtt_host -t "/carriage/+/apply_brake" | while read line; do
    log_message $line
    carriage_number=$(echo $line | cut -f 3 -d'/')
    apply_brake $carriage_number
done

# Kill background processes on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
