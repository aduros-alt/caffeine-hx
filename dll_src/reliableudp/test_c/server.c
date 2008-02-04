#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "enet/enet.h"

void service(ENetHost *client) {
    ENetEvent event;
    
    /* Wait up to 1000 milliseconds for an event. */
    while (enet_host_service (client, & event, 1000) > 0)
    {
        switch (event.type)
        {
        case ENET_EVENT_TYPE_CONNECT:
            printf ("A new client connected from %x:%u.\n", 
                    event.peer -> address.host,
                    event.peer -> address.port);

            /* Store any relevant client information here. */
            event.peer -> data = "Client information";


	    ENetPacket *packet = enet_packet_create ("packet",
                strlen ("packet") + 1,
                ENET_PACKET_FLAG_RELIABLE);
            enet_peer_send (event.peer, 0, packet);
            //enet_host_flush( event.peer );

            break;

        case ENET_EVENT_TYPE_RECEIVE:
            printf ("A packet of length %u containing %.*s was received from %s on channel %u port %u.\n",
                    event.packet -> dataLength,
		    event.packet -> dataLength,
                    event.packet -> data,
                    event.peer -> data,
                    event.channelID,
		    event.peer -> address.port);
	    ENetPacket *packetresp = enet_packet_create(
		event.packet->data,
		event.packet->dataLength,
                ENET_PACKET_FLAG_RELIABLE);
	    	//ENET_PACKET_FLAG_NO_ALLOCATE | ENET_PACKET_FLAG_RELIABLE);
            enet_peer_send (event.peer, 0, packetresp);
            /* Clean up the packet now that we're done using it. */
            enet_packet_destroy (event.packet);
            
            break;
           
        case ENET_EVENT_TYPE_DISCONNECT:
            printf ("%s disconected.\n", event.peer -> data);

            /* Reset the peer's client information. */

            event.peer -> data = NULL;
        }
    }
}

//typedef struct
//{
//    void * data;
//    size_t dataLength;
//} ENetBuffer;
void introduce(ENetHost *me, const char *remotehost, int port) {
	ENetAddress address;
	//ENetSocket sock;
	ENetBuffer buf;

	printf("Sending intro\n");
	buf.data = "HI";
	buf.dataLength = 2;
	enet_address_set_host (& address, remotehost);
	address.port = port;
	//sock = enet_socket_create(ENET_SOCKET_TYPE_DATAGRAM, NULL); // no address means not to bind 
	enet_socket_send (me->socket, &address, &buf, 1);
	//enet_socket_destroy(sock);

}

int main (int argc, char ** argv) 
{
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        return EXIT_FAILURE;
    }
    atexit (enet_deinitialize);

    ENetAddress address;
    ENetHost * server;

    /* Bind the server to the default localhost.     */
    /* A specific host address can be specified by   */
    /* enet_address_set_host (& address, "x.x.x.x"); */

    address.host = ENET_HOST_ANY;
    /* Bind the server to port 1234. */
    address.port = 8000;

    server = enet_host_create (& address /* the address to bind the server host to */, 
                                 32      /* allow up to 32 clients and/or outgoing connections */,
                                  0      /* assume any amount of incoming bandwidth */,
                                  0      /* assume any amount of outgoing bandwidth */);
    if (server == NULL)
    {
        fprintf (stderr, 
                 "An error occurred while trying to create an ENet server host.\n");
        exit (EXIT_FAILURE);
    }
    int x;
    //for(x = 0; x < 30; x++)
    if(strcmp(argv[1], "10.0.0.103")) {
      introduce(server, "10.0.0.103", 8000);
    }
    while(1) { 
      service(server);
    }
    printf("Exiting...\n");
    enet_host_destroy(server);
}

//typedef struct _ENetEvent
//{
//   ENetEventType        type;      /**< type of the event */
//   ENetPeer *           peer;      /**< peer that generated a connect, disconnect or receive event */
//   enet_uint8           channelID; /**< channel on the peer that generated the event, if appropriate */
//   enet_uint32          data;      /**< data associated with the event, if appropriate */
//   ENetPacket *         packet;    /**< packet associated with the event, if appropriate */
//} ENetEvent

