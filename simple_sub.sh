#!/bin/bash
# this is a simple skeleton script that will sub to a topic and process anything that arrives line by line.

# subscribe to topic and process new lines one at a time in a while loop
# note the v option gives us the topic AND the message
mosquitto_sub -v -h localhost -t /simpletest/# | while read line; do
    # is this simple example all we do is echo the line to the screen
    echo $line
    # how about we cut out a field
    topicF1=$(echo $line | cut -f3 -d/)
    echo topic field 1 is: $topicF1
    topicF2=$(echo $line | cut -f4 -d/)
    echo topic field 2 is: $topicF2
    topicM=$(echo $line | cut -f2 -d' ')
    echo message: $topicM

    case "$topicF1" in
    carriage[0-9])
        case "$topicM" in
        ON | OFF)
            echo "$topicF1: $topicM" >dash-$topicF1
            ;;
        *)
            echo Received bad data
            ;;
        esac
        ;;
    esac
done
