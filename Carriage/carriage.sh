#!/bin/bash
#
# USAGE
# carriage [-h mqtt_host] [-c carriage_number]
#
# DESCRIPION
# This script implements the functions of the carriage system for the bash MQTT train intercomm system
#
# The main messages which are processed:
#
# 1. Emergency brake handle.
# Each carriage has an emergency brake handle that allows a passenger to request the driver system
# to activate the brakes. This is implemented by sending an MQTT message to a topic requesting that the brakes be activated.
#
# 2. Messages to driver
# Each carriage has a system to allow a passenger to send and receive brief text messages to and from the driver. This is implemented by
# publishing messages to an MQTT topic to send messages and subscribing to an MQTT topic to receive messages.
#
carriage_number=1 # What carriage number are we? Default to 1

mqtt_host="${MQTT_HOST:-localhost}" # Set mqtt_host based on environment variable. Default to localhost

while getopts "h:c:" OPTION; do
    case $OPTION in
    c)
        carriage_number=$OPTARG
        ;;
    h)
        mqtt_host=$OPTARG
        ;;
    *)
        echo "Usage: $(basename $0) [-h mqtt_host] [-c carriage_number]"
        exit 1
        ;;
    esac
done
#
#
echo "Carriage number is " $carriage_number
echo "MQTT host IS " $mqtt_host
#
# Menu setup
#
menu_options=("Apply brake" "Send message")
menu_title="Select an option "
menu_prompt="Menu choice: "
driver_message_prompt="Enter message for driver: "

# Usage: send_message msg
# Prompt user for a message and publish it to the message topic
# Note the carriage number is part of the topic.
#
send_message() {
    read -p "$driver_message_prompt" driver_message
    mosquitto_pub -h $mqtt_host -t "/carriage/$carriage_number/message" -m "$driver_message"
}

# Usage: apply_brake
# Send an MQTT message to the apply_brake topic. The carriage number if part of the topic.
#
apply_brake() {
    echo "activating brake"
    mosquitto_pub -h $mqtt_host -t "/carriage/$carriage_number/apply_brake" -m "activate"
}

#
# Subscribe to broadcast messages from driver
#
mosquitto_sub -h $mqtt_host -t "/driver/message/broadcast" | while read line; do
    # Display the message received to the user
    echo
    echo Message received from driver: $line
done & # Run in the background

mosquitto_sub -h $mqtt_host -t "/driver/messsage/$carriage_number" | while read line; do
    # Display the message received to the user
    echo
    echo Message received from driver: $line
done & # Run in the background

#
# Display a menu of available options and ask the user to choose
#
PS3=$menu_prompt
echo $menu_title
select menu_item in "${menu_options[@]}" "Quit"; do
    case $menu_item in
    "Apply brake")
        apply_brake
        ;;
    "Send message")
        send_message
        ;;
    "Quit")
        echo Goodbye
        break
        ;;
    *)
        echo "Invalid option. Please choose a valid option"
        ;;
    esac
done
