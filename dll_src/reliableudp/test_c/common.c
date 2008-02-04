#include <stdio.h>
#include <stdlib.h>
#include "enet/enet.h"
#include <string.h>

void service(ENetHost *client) {
    ENetEvent event;
    
    /* Wait up to 1000 milliseconds for an event. */
    while (enet_host_service (client, & event, 10) > 0)
    {
        switch (event.type)
        {
        case ENET_EVENT_TYPE_CONNECT:
            printf (">> received CONNECT from %x:%u.\n", 
                    event.peer -> address.host,
                    event.peer -> address.port);

            /* Store any relevant client information here. */
            event.peer -> data = "Client information";

            break;

        case ENET_EVENT_TYPE_RECEIVE:
            printf (">> A packet of length %u containing %s was received from %s on channel %u.\n",
                    event.packet -> dataLength,
                    event.packet -> data,
                    event.peer -> data,
                    event.channelID);

            /* Clean up the packet now that we're done using it. */
            enet_packet_destroy (event.packet);
            
            break;
           
        case ENET_EVENT_TYPE_DISCONNECT:
            printf (">> %s disconected.\n", event.peer -> data);

            /* Reset the peer's client information. */

            event.peer -> data = NULL;
        }
    }
}

ENetPeer* sconnect(ENetHost * client, char *host, int port) {
    ENetAddress address;
    ENetEvent event;
    ENetPeer *peer;

    /* Connect to some.server.net:1234. */
    //enet_address_set_host (& address, "10.0.0.103");
    enet_address_set_host (& address, host);
    address.port = port;

    /* Initiate the connection, allocating the two channels 0 and 1. */
    peer = enet_host_connect (client, & address, 2);    
    
    if (peer == NULL)
    {
       fprintf (stderr, 
                "No available peers for initiating an ENet connection.\n");
	return NULL;
    }
    
    /* Wait up to 5 seconds for the connection attempt to succeed. */
    if (enet_host_service (client, & event, 5000) > 0 &&
        event.type == ENET_EVENT_TYPE_CONNECT)
    {
        puts ("Connection to some.server.net:1234 succeeded.");
	return peer;
    }

        /* Either the 5 seconds are up or a disconnect event was */
        /* received. Reset the peer in the event the 5 seconds   */
        /* had run out without any significant event.            */
        enet_peer_reset (peer);

        printf("Connection to %s:%d failed.", host, port);
	return NULL;
}

void sdisconnect(ENetHost *client, 
	ENetPeer *peer
	) 
{
    ENetEvent event;
    enet_peer_disconnect (peer, 0);

    /* Allow up to 3 seconds for the disconnect to succeed
       and drop any packets received packets.
    */
    while (enet_host_service (client, & event, 3000) > 0)
    {
        switch (event.type)
        {
        case ENET_EVENT_TYPE_RECEIVE:
            enet_packet_destroy (event.packet);
            break;

        case ENET_EVENT_TYPE_DISCONNECT:
            puts ("Disconnection succeeded.");
            return;
        }
    }
    
    /* We've arrived here, so the disconnect attempt didn't */
    /* succeed yet.  Force the connection down.             */
    enet_peer_reset (peer);
}


//typedef struct _ENetEvent
//{
//   ENetEventType        type;      /**< type of the event */
//   ENetPeer *           peer;      /**< peer that generated a connect, disconnect or receive event */
//   enet_uint8           channelID; /**< channel on the peer that generated the event, if appropriate */
//   enet_uint32          data;      /**< data associated with the event, if appropriate */
//   ENetPacket *         packet;    /**< packet associated with the event, if appropriate */
//} ENetEvent



