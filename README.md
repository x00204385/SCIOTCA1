# OVERVIEW
Implements an MQTT system with bash clients to simulate a train intercom system. We have a train with a driver control system and 2 passenger carriages. The driver and carriage system process messages using pub/sub to MQTT topics which implement the functionality required;
- Brake management. Carriages can request brake activation. Brakes are applied for a configurable amount of time and then released.
- Messaging. Driver can broadcast to carriages or send individual messages. Carriages can send to driver but not to each other.

# OUTLINE DESIGN

- Driver system consisting of 2 bash scripts running in a single docker image. 
-  Carriage 1 and Carriage 2. Carriage 1 and Carriage 2 run identical code. A command line argument determines whether the code behaves
as carriage 1 or carriage 2. Each runs in a separate docker process. 

``` 
                                           ----------------------                                           
                                          |      MQTT           |                                            
                                          |      Broker         |                                            
                 |----------------------->|                     |<-------------------------|                 
                 |                        |                     |                          |                 
                 |                        |----------^-----------                          |                 
                 |                                   |                                     |                 
                 |                                   |                                     |                 
                 |                                   |                                     |                 
                 |                                   |                                     |                 
                 |                                   |                                     |                 
                 |                                   |                                     |                
     |-----------V-----------|            |----------V------------|            |-----------V-----------|     
     |                       |            |                       |-           |                       |     
     |      Driver           |            |     Carriage 1        |-           |     Carriage 2        |     
     |                       |            |                       |-           |                       |     
     |                       |            |                       |-           |                       |     
     -------------------------            -------------------------            -------------------------     

```

# Starting the system
## Start driver system
```
docker import driver.docker
docker run -it <sha> bash
service mosquitto start
cd /root/SCIOTCA1/Driver
./driver_system.sh -h 172.18.0.2
```

## Start carriage system (1)
```
docker import carriage.docker
docker run -it <sha> bash
cd /root/SCIOT/SCIOTCA1/Carriage
./carriage.sh -h 172.18.0.2 -c 1
```

## Start carriage system (2)
```
docker run -it <sha> bash
cd /root/SCIOT/SCIOTCA1/Carriage
./carriage.sh -h 172.18.0.2 -c 2
```

# MQTT Topics

Communication in the intercomm system is via the MQTT broker. Each script will publish messages to a topic to indicate an event 
within the system. For example, when a user activates the brakes in Carriage 1 a message will be published to the topic "/carriage/1/apply_brake" with the message "activate". The Driver system will receive that message because it subscribed to all messages from the carriagem"/carriage/#". 

The structure of topics published by the driver system are of the form "/driver/topic".

The structure of topics published by the carriage system are of the form "/carriage/carriage_number/topic". In the system design there are only 2 carriages so carriage_number is either 1 or 2.

In detail, the possible messages are:

Published by driver:
/carriage/carriage_number/brake: 	Activate or deactive the brakes. The message content can be either ON or OFF indicating which.
/driver/message/broadcast:			Send a message to all carriages. 
/driver/message/carriage_number:	Send a message to the specified carriage. 

Published by the carriage:
/carriage/carriage_number/message 	Send a message from carriage carriage_number to the driver.
/carriage/carriage_number/apply_brake
									Request from carriage carriage_number to apply the brake in that carriage. 
