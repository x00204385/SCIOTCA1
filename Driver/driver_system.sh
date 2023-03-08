#!/bin/bash
#
#
# driver_system.sh
# USAGE
# driver_system
# DESCRIPION
# This script implements the functions of the driver system for the bash MQTT train intercomm system
# The script subscribes to a number of MQTT topics and responds if a message is received. Messages received are logged to a
# log file which is truncated to a configureable maximum number of lines.
#
# The main messages which are processed:
#
# 1. Brake activiation messages from carriages.
# The brakes are set to ON when a message is received. After a configurable period the brakes are restored to OFF. MQTT are posted when
# messages brakes are turned OFF or ON
#
# 2. Messages from carriages
# The messages are logged in the log file
#
# The script also implements a menu system that gives the driver the option to send messages to the carriages, either
# broadcast or to a selected carriage. Messages received from carriages are displayed on the terminal and logged to the log file.
#
#
mqtt_host="${MQTT_HOST:-localhost}" # Set mqtt_host based on environment variable. Default to localhost
brake_duration=10
log_file_maxlen=20
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
done &

#
# Parse command line options
#
#
# Process command line options
#
while getopts "h:l:" OPTION; do
    case $OPTION in
    l)
        log_file_maxlen=$OPTARG
        ;;
    h)
        mqtt_host=$OPTARG
        ;;
    *)
        echo "Usage: $(basename $0) [-h mqtt_host] [-l log_file_maxlen]"
        exit 1
        ;;
    esac
done
#
echo mqtt_host is $mqtt_host
echo log_file_maxlen is $log_file_maxlen

temp_file=/tmp/$$temp.txt
log_file="./driver.log"
log_message() {
    echo $(date +"%H:%M:%S") $* >>$log_file
    # Crop log file to 20 lines max
    tail -n $log_file_maxlen $log_file >$temp_file
    mv $temp_file $log_file
}

#
# Usage: broadcast_message_to_carriages message
# Send a message to all carriages
#
broadcast_message_to_carriages() {
    read -p "$driver_message_prompt" driver_message
    mosquitto_pub -h $mqtt_host -t "/driver/message/broadcast" -m "$driver_message"
    log_message "Broadcast /driver/message/broadcast  " $driver_message
}

#
# Usage: send_message_to_carriage
# Send a message to specific carriage. Prompt user for detail.
#
send_message_to_carriage() {
    select num in "1" "2" "Quit"; do
        case $num in
        "1" | "2")
            break
            ;;
        *)
            echo "Please select a valid option"
            ;;
        esac
    done
    # Read user input
    read -p "$driver_message_prompt" driver_message
    #
    # Post the message by publishing to MQTT topic
    #
    mosquitto_pub -h $mqtt_host -t "/driver/messsage/$num" -m "$driver_message"
}

# Listen for messages from carriages (in the background)

mosquitto_sub -v -h $mqtt_host -t "/carriage/+/message" | while read line; do
    carriage_number=$(echo $line | cut -f 3 -d'/')
    echo "Message received from carriage $carriage_number" $line
    log_message "Message received from carriage $carriage_number" $line
done &

#
# Display a menu of available options and ask the user to choose
#
# Menu setup
menu_options=("Broadcast to carriages" "Direct message to carriage")
menu_title="Driver menu "
menu_prompt="Menu choice: "
PS3=$menu_prompt
echo $menu_title
select menu_item in "${menu_options[@]}" "Quit"; do
    case $menu_item in
    "Broadcast to carriages")
        broadcast_message_to_carriages
        ;;
    "Direct message to carriage")
        send_message_to_carriage
        ;;
    "Quit")
        echo Goodbye
        break
        ;;
    *)
        echo "Invalid option. Please choose a valid option"
        ;;
    esac
    # Trick to refresh menu
    REPLY=
done

# Kill background processes on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
