#include <stdio.h>
#include <stdlib.h>
#include "enet/enet.h"
#include <string.h>

ENetPeer* sconnect(ENetHost * client, char *host, int port);

int main (int argc, char ** argv) 
{
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        return EXIT_FAILURE;
    }
    atexit (enet_deinitialize);

    ENetAddress address;
    ENetHost * client;

    /* Bind the server to the default localhost.     */
    /* A specific host address can be specified by   */
    /* enet_address_set_host (& address, "x.x.x.x"); */

    address.host = ENET_HOST_ANY;
    /* Bind the server to port 1234. */
    address.port = 1234;

    client = enet_host_create (NULL /* the address to bind the server host to */, 
                                 1      /* allow up to 32 clients and/or outgoing connections */,
                                  0      /* assume any amount of incoming bandwidth */,
                                  0      /* assume any amount of outgoing bandwidth */);
    if (client == NULL)
    {
        printf ("An error occurred while trying to create an ENet client host.\n");
        exit (EXIT_FAILURE);
    }

    if(argc != 3) {
	printf("Usage: client ip port");
	exit(1);
    }

printf("%d\n", atoi(argv[2]));
    ENetPeer* server = sconnect(client, argv[1], atoi(argv[2]));

    if(server == NULL) {
	printf("Could not connect.\n");
	exit(1);
    }

    //while(1)
    //{
      ENetPacket *packet = enet_packet_create ("packet", 
		strlen ("packet") + 1, 
		ENET_PACKET_FLAG_RELIABLE);
      enet_peer_send (server, 0, packet);
      //enet_host_flush( client);
      service(client);
    //}
    sdisconnect(client, server);
    printf("Client exiting...\n");
    enet_host_destroy(client);
}

//typedef struct _ENetEvent
//{
//   ENetEventType        type;      /**< type of the event */
//   ENetPeer *           peer;      /**< peer that generated a connect, disconnect or receive event */
//   enet_uint8           channelID; /**< channel on the peer that generated the event, if appropriate */
//   enet_uint32          data;      /**< data associated with the event, if appropriate */
//   ENetPacket *         packet;    /**< packet associated with the event, if appropriate */
//} ENetEvent



