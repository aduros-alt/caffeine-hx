/*
* Copyright (c) 2008, Russell Weir, The haXe Project Contributors
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted
* provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice, this list of conditions
*  and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this list of conditions
*  and the following disclaimer in the documentation and/or other materials provided with the distribution.
* - Neither the name of the author nor the names of its contributors may be used to endorse or promote
*  products derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <neko/neko.h>
#include "enet/enet.h"

// for enumerating ip addresses
#ifdef NEKO_WINDOWS
#include <winsock2.h>
#else
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <net/if.h>
#endif

#define SOCKET_ERROR (-1)
#define val_mythread(t)   ((vthread*)val_data(t))

DEFINE_KIND(k_udprhost);
DEFINE_KIND(k_udprpeer);
DEFINE_KIND(k_udprevent);

typedef enet_uint16 ENetPeerHandle;
#define PEER_HANDLE_VALID(host,hndPeer) (((hndPeer) < (host) -> peerCount) ? 1 : 0)
#define INVALID_PEER_HANDLE(host)	((host) -> peerCount)
#define HOST_HANDLE(host)           ((host) -> peerCount)

ENetPeerHandle
enet_host_peer_to_handle(ENetHost * host, ENetPeer *peer)
{
       ENetPeer * currentPeer;
       for (currentPeer = host -> peers;
         currentPeer < & host -> peers [host -> peerCount];
         ++ currentPeer)
         if(currentPeer == peer)
               return currentPeer -> incomingPeerID;
    return HOST_HANDLE(host);
}

ENetPeer *
enet_host_handle_to_peer(ENetHost * host, ENetPeerHandle hndPeer)
{
       if(!PEER_HANDLE_VALID(host, hndPeer))
               return NULL;
       return & host -> peers[hndPeer];
}

/**
	Initialize the Enet library.
**/
static value udpr_init() {
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        exit(EXIT_FAILURE);
    }
    atexit (enet_deinitialize);
    return val_true;
}

//void free_peer_event( ENetPeer * peer ) {
	//ENetEvent * event = peer->data;
	//if(event == NULL)
		//return;
	//if(event->packet != NULL)
		//enet_packet_destroy (event->packet);
	//peer->data = NULL;
//}

/**
	Adds an event to the peer in the event. The passed pointer
	must be to an allocated ENetEvent struct. Will automatically
	delete existing peer event if one already exists.
**/
//void add_peer_event( ENetEvent *event ) {
//	if(event->peer != NULL) {
		//if(event->peer->data != NULL)
			//free_peer_event(event->peer);
		//event->peer->data = event;
	//}
//}

/**
	Destroy an allocated ENetHost pointer. Must be used with val_gc() for every ENetHost created.
*/
static void destroy_enethost( value h ) {
#ifdef ENET_DEBUG
	fprintf(stderr, "*** destroy_enethost\n");
	//exit(0);
#endif
//return;
	if(!val_is_kind(h, k_udprhost))
		return;
	ENetHost *host = (ENetHost *)val_data(h);
	ENetPeer *peer;
	//int x, count;
	if(host == NULL)
		return;
	enet_host_flush( host );
	for (peer = host->peers;
         peer < &host->peers[host->peerCount];
         ++peer)
    {
    	if (peer->state == ENET_PEER_STATE_CONNECTED) {
    		enet_peer_disconnect_now(peer, 0);
    	}
    }

#ifdef ENET_DEBUG
	fprintf(stderr, "*** destroy_enethost\n");
#endif
	enet_host_destroy( host );
	//val_kind(v) = NULL;
#ifdef ENET_DEBUG
	fprintf(stderr, "*** destroy_enethost done.\n");
#endif
	return;
}

/**
	Destroy an ENetPeer structure.
**/
static void destroy_enetpeer( value p ) {
#ifdef ENET_DEBUG
	fprintf(stderr, "*** destroy_enetpeer\n");
	exit(0);
#endif
return;
	ENetPeer *peer;
	if(!val_is_abstract(p) || !val_is_kind(p, k_udprpeer))
		return;
	peer = (ENetPeer *)val_data(p);
	if(peer == NULL)
		return;

	// force immediate disconnect, if still connected.
	enet_peer_disconnect_now(peer, 0);

	// if the peer has an event still, destroy it
	//free_peer_event(peer);

	// clear the peer structure
	enet_peer_reset(peer);

	// peers never need be deallocated, they are part of an ENetHost
#ifdef ENET_DEBUG
	fprintf(stderr, "*** destroy_enetpeer done.\n");
#endif
	return;
}

/**
	Destroy an allocated ENetEvent struct
**/
static void destroy_enetevent( value e ) {
	ENetEvent *event;
	if( !val_is_abstract(e) || !val_is_kind(e,k_udprevent) )
		return;
	event = (ENetEvent *)val_data(e);
	if(e == NULL)
		return;

	// enet_packet_destroy frees the packet itself.
#ifdef ENET_DEBUG
printf("*** destroy_enetevent freeing packet\n");
#endif
	if(event->packet != NULL)
		enet_packet_destroy (event->packet);
	//if(event->type == ENET_EVENT_TYPE_DISCONNECT
		//&& event->peer->data != NULL)
			//enet_free(event->peer -> data);
#ifdef ENET_DEBUG
//printf("*** destroy_enetevent freeing event\n");
#endif
	enet_free(event);
#ifdef ENET_DEBUG
//printf("*** destroy_enetevent done.\n");
#endif
	return;
}

/**
	Free an allocated ENetEvent struct from neko
**/
static value free_enetevent( value e ) {
	val_check_kind(e,k_udprevent);

	ENetEvent *event = (ENetEvent *)val_data(e);
	if(e == NULL)
		neko_error();

	// enet_packet_destroy frees the packet itself.
#ifdef ENET_DEBUG
printf("*** free_enetevent freeing packet\n");
#endif
	if(event->packet != NULL)
		enet_packet_destroy (event->packet);
#ifdef ENET_DEBUG
//printf("*** free_enetevent freeing event\n");
#endif
	enet_free(event);
	val_gc(e,NULL);
	val_kind(e) = NULL;
#ifdef ENET_DEBUG
//printf("*** free_enetevent done.\n");
#endif
	return val_true;
}
DEFINE_PRIM(free_enetevent,1);


/**
	Take a
**/
	// TODO: check if this is right
	// sync with udpr_connect() below
static value populate_address(ENetAddress *a, value ip, value port) {
	if(!val_is_null(ip))
		val_check(ip,int32);
	val_check(port,int);

	if(!val_is_null(ip) && val_int32(ip) != 0) {
		a->host = val_int32(ip);
		//a->host = htonl(val_int32(ip));
	}
	else {
#ifdef ENET_DEBUG
		fprintf(stderr, "populate_address: null ip\n");
#endif
		a->host = ENET_HOST_ANY;
	}
	a->port = val_int(port); //htons(val_int(port))
#ifdef ENET_DEBUG
	fprintf(stderr, "populate_address: %x:%u from %x:%u\n", a->host, a->port, val_is_null(ip)?0:val_int32(ip),val_int(port));
#endif
	return val_true;
}

/**
        socket_bind : host : int32 -> port:int -> connections:int -> incoming:int32 -> outgoing:int32 -> bool
        <doc>Bind a UDPR socket for server usage on the given host and port, with max connections,
        incoming bandwidth limited to bytes per second or 0 for unlimited, outgoing also. Host may be
        val_type_null, in which case the binding is to ENET_HOST_ANY
        </doc>
**/
static value udpr_bind( value ip, value port, value connections, value incoming, value outgoing ) {
	ENetAddress address;
	ENetHost *s;
	val_check(connections,int);
	val_check(incoming,int32);
	val_check(outgoing,int32);
	if(populate_address(& address, ip, port) != val_true)
		neko_error();

	s = enet_host_create(	&address,
							(size_t)val_int(connections), 		/* number of clients and/or outgoing connections */
							(enet_uint32)val_int32(incoming),	/* amount of incoming bandwidth in Bytes/sec */
							(enet_uint32)val_int32(outgoing));
	if(s == NULL)
		neko_error();
	value v = alloc_abstract(k_udprhost,s);
	val_gc(v, destroy_enethost);
#ifdef ENET_DEBUG
	fprintf(stderr, "udpr_bind: complete\n");
#endif
	return v;
}

/**
	Create a client side ENetHost with 'connections' max outgoing connections
	using the specified bandwidth limits.
**/
static value udpr_client_create(value connections, value incoming, value outgoing)
{
	ENetHost *h;
	h = enet_host_create(	NULL,
							(size_t)val_int(connections), 		/* number of clients and/or outgoing connections */
							(enet_uint32)val_int32(incoming),	/* amount of incoming bandwidth in Bytes/sec */
							(enet_uint32)val_int32(outgoing));
	if(h == NULL)
		//val_throw(alloc_string("Host creation failure"));
		neko_error();
	value v = alloc_abstract(k_udprhost,h);
	val_gc(v, destroy_enethost);
	return v;
}

/**
	Returns an ENetPeer *, or throw if connection fails.
**/
static value udpr_connect(value h, value ip, value port, value channels, value timeout) {
    ENetAddress address;
    ENetEvent event;
    ENetHost *host;
    ENetPeer *peer;
    int to;

	if( !val_is_abstract(h) || !val_is_kind(h,k_udprhost) )
		neko_error();

	// checked in address population
	//val_check(ip,int);
	//val_check(port,int);
	val_check(channels,int);
	val_check(timeout,int);
	to = val_int(timeout);
	if(to < 0)
		to = 5000;

	host = (ENetHost *)val_data(h);
	if(populate_address(&address, ip, port) != val_true)
		neko_error();

    // Initiate the connection with channels 0..channels-1
    peer = enet_host_connect (host, &address, (size_t)val_int(channels));
    if (peer == NULL)
    	neko_error();

#ifdef ENET_DEBUG
		fprintf(stderr, "udpr_connect: waiting %d\n", to);
#endif
    /* Wait up to 5 seconds for the connection attempt to succeed. */
    if (enet_host_service (host, & event, to) > 0 &&
        event.type == ENET_EVENT_TYPE_CONNECT)
    {
    	// success
#ifdef ENET_DEBUG
		fprintf(stderr, "udpr_connect: returning peer %x\n", peer);
#endif
		value v = alloc_abstract(k_udprpeer,peer);
		//val_gc(v, destroy_enetpeer);
		return v;
    }

	// timeout has occurred or disconnect received.
#ifdef ENET_DEBUG
	fprintf(stderr, "udpr_connect: *** enet_peer_reset\n");
#endif
    enet_peer_reset (peer);
    neko_error();
}
DEFINE_PRIM(udpr_connect,5);

/**
	Connect out from a server socket.
	Returns an ENetPeer *, which has not yet connected, or throws if connection fails.
**/
static value udpr_connect_out(value h, value ip, value port, value channels, value timeout) {
    ENetAddress address;
    ENetEvent event;
    ENetHost *host;
    ENetPeer *peer;
    int to;

	val_check_kind(h,k_udprhost);

	// checked in address population
	//val_check(ip,int);
	//val_check(port,int);
	val_check(channels,int);
	val_check(timeout,int);
	to = val_int(timeout);
	if(to < 0)
		to = 5000;

	host = (ENetHost *)val_data(h);
	if(populate_address(&address, ip, port) != val_true)
		val_throw(alloc_string("address"));
		//neko_error();

    // Initiate the connection with channels 0..channels-1
    peer = enet_host_connect (host, &address, (size_t)val_int(channels));
    if (peer == NULL)
    	//val_throw( alloc_string("Host not found") );
    	neko_error();

 	value v = alloc_abstract(k_udprpeer,peer);
	return v;
}
DEFINE_PRIM(udpr_connect_out,5);

/**
	Requests a graceful close. Do not use for server peers, as
	this waits and destroys all incoming packets.
	The wrapper must set the abstract peer to null.
**/
static value udpr_close(value h, value p)
{
#ifdef ENET_DEBUG
	fprintf(stderr, "udpr_close:\n");
#endif
	ENetHost *host;
    ENetPeer *peer;
    ENetEvent event;

	val_check_kind(h,k_udprhost);
	val_check_kind(p,k_udprpeer);
    host = (ENetHost *)val_data(h);
    peer = (ENetPeer *)val_data(p);
	//event = (ENetEvent *)enet_malloc(sizeof(ENetEvent));

    enet_peer_disconnect (peer, 0);

    // 3 seconds to wait for graceful close, dropping
    // any other packets.
    while (enet_host_service (host, & event, 3000) > 0)
    {
        switch (event.type)
        {
        case ENET_EVENT_TYPE_RECEIVE:
            enet_packet_destroy (event.packet);
            break;

        case ENET_EVENT_TYPE_DISCONNECT:
            return val_true;
			break;

        default:
        	break;
        }
    }
    // disconnect did not work. Force close.
#ifdef ENET_DEBUG
	fprintf(stderr, "udpr_close: *** enet_peer_reset\n");
#endif
    enet_peer_reset (peer);
    return val_true;
}
DEFINE_PRIM(udpr_close,2);

static value udpr_close_graceful(value p)
{
	val_check_kind(p,k_udprpeer);
//#ifdef NEKO_WINDOWS
//    enet_peer_disconnect_later((ENetPeer *)val_data(p), 0);
//#else
    enet_peer_disconnect((ENetPeer *)val_data(p), 0);
//#endif
    return val_true;
}
DEFINE_PRIM(udpr_close_graceful,1);

static value udpr_close_now(value p)
{
	// in order to avoid this, the library would have to queue events
	// and handle them in select() and add to them in udpr_close()
	val_check_kind(p,k_udprpeer);
    enet_peer_disconnect_now((ENetPeer *)val_data(p), 0);
    return val_true;
}
DEFINE_PRIM(udpr_close_now,1);

#ifdef ENET_DEBUG
const char* event_to_string(int evt) {
	switch(evt) {
	case ENET_EVENT_TYPE_NONE:
		return "ENET_EVENT_TYPE_NONE";
	case ENET_EVENT_TYPE_CONNECT:
		return "ENET_EVENT_TYPE_CONNECT";
	case ENET_EVENT_TYPE_RECEIVE:
		return "ENET_EVENT_TYPE_RECEIVE";
	case ENET_EVENT_TYPE_DISCONNECT:
		return "ENET_EVENT_TYPE_DISCONNECT";
	}
	return "ENET_EVENT_UNKNOWN";
}
#endif

/**
	Returns the ENetPeer that generated an event, with the Event
	allocated pointer in Peer->data. The returned ENetPeer must not
	be destroyed, since it's a copy of an existing peer pointer.
	Timeout is float number of seconds (0.001 == 1 ms)
**/
static value udpr_poll(value h, value timeout)
{
	//ENetPeerHandle hndPeer = enet_host_peer_to_handle(host, event->peer);
    ENetEvent *event;
    int res;

	if( !val_is_abstract(h) || !val_is_kind(h,k_udprhost) )
		neko_error();

	val_check(timeout,number);
	enet_uint32 tout = (enet_uint32)(val_number(timeout)*1000);

	event = (ENetEvent *) enet_malloc (sizeof (ENetEvent));

    // Wait up to timeout milliseconds for an event.

    res = enet_host_service ((ENetHost *)val_data(h), event, tout);
    if(res <= 0) {
    	if(res == 0)
    		return val_null;
    	neko_error();
    }

	switch (event->type)
	{
	case ENET_EVENT_TYPE_NONE:
		//if(event->peer != NULL)
			//free_peer_event(event->peer);
		enet_free(event);
		return val_null;
		break;
	default:
		// auto frees any existing unhandled event, add this event.
#ifdef ENET_DEBUG_FULL
		if(event->type == ENET_EVENT_TYPE_RECEIVE)
			fprintf(stderr, "udpr_poll: event type %s %0.*s\n", event_to_string(event->type), event->packet->dataLength, event->packet->data);
		else
			fprintf(stderr, "udpr_poll: event type %s\n", event_to_string(event->type));
#endif
		break;
	}

	value v = alloc_abstract(k_udprevent,event);
	val_gc(v, destroy_enetevent);
	return v;
#ifdef ENET_DEBUG
	//fprintf(stderr, "udpr_poll: returning peer %x\n", event->peer);
#endif
	//value v = alloc_abstract(k_udprpeer, event->peer);
	//return v;
}

/**
	Set the in and out speeds of a host in Bytes per second.
**/
static value udpr_setrate(value o, value in, value out)
{
    if( !val_is_abstract(o) || !val_is_kind(o,k_udprhost) )
		neko_error();
	enet_host_bandwidth_limit((ENetHost *)val_data(o), (enet_uint32)val_int32(in), (enet_uint32)val_int32(out));
	return val_true;
}

/**
	Returns the maximum peers allowed for a ENetHost (0x7FFF)
**/
static value udpr_max_peers(void)
{
	return alloc_int(ENET_PROTOCOL_MAXIMUM_PEER_ID);
}

/**
	Returns the max number of channels per connection (255)
**/
static value udpr_max_channels(void)
{
	return alloc_int(ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT);
}

/**
	Send an OOB packet for NAT punching.
	ENetHost->String->Int->val_true
**/
static value udpr_send_oob(value h, value ip, value port, value data) {
	ENetAddress address;
	ENetHost *host;
	ENetBuffer buf;

	val_check_kind(h,k_udprhost);
	val_check(data,string);

	host = (ENetHost *)val_data(h);
	if(host == NULL)
		neko_error();

	if(populate_address(&address, ip, port) != val_true)
		neko_error();
	buf.data = val_string(data);
	buf.dataLength = val_strlen(data);

	enet_socket_send (host->socket, &address, &buf, 1);
	return val_true;
}
DEFINE_PRIM(udpr_send_oob,4);

/**
	udpr_write : ENetPeer-> data:string -> Channel->Reliable:Bool->void
	Send a full string [data]
**/
static value udpr_write(value p, value data, value chan, value reliable)
{
	ENetPeer *peer;
	ENetPacket *packet;
	int c;
	val_check_kind(p,k_udprpeer);
	val_check(data,string);
	val_check(chan,int);
	val_check(reliable,bool);

	c = val_int(chan);
	peer = (ENetPeer *)val_data(p);
#ifdef ENET_DEBUG_FULL
	fprintf(stderr, "udpr_write: Writing packet '%s' to peer %x on channel %d\n", val_string(data), peer, c);
	fprintf(stderr, "peer state: %d peer channels: %d\n", peer -> state, peer->channelCount);
#endif
	if(peer == NULL || c < 0 || c > 255)
		neko_error();

	packet = enet_packet_create(
		val_string(data),
		val_strlen(data),
		val_bool(reliable) ? ENET_PACKET_FLAG_RELIABLE : 0);
    if(enet_peer_send(peer, c, packet)) {
#ifdef ENET_DEBUG
		fprintf(stderr, "ERROR: udpr_write: enet_peer_send error\n");
		fprintf(stderr, "peer state: %d peer channels: %d\n", peer -> state, peer->channelCount);
#endif
    	neko_error();
    }
	return val_true;
}

/**
        udpr_send : peer -> data:string -> pos:int -> len:int -> chan:int -> reliable:bool -> int
        Send up to [len] bytes from [buf] starting at [pos] over a connected socket on channel [chan]
        using reliable setting [reliable]
        Return the number of bytes sent.
**/
static value udpr_send( value p, value data, value pos, value len, value chan, value reliable ) {
	ENetPeer *peer;
	ENetPacket *packet;
	int pp,l,sLen,c;
	val_check_kind(p,k_udprpeer);
	val_check(data,string);
	val_check(pos,int);
	val_check(len,int);
	val_check(chan,int);
	val_check(reliable,bool);

	peer = (ENetPeer *)val_data(p);
	pp = val_int(pos);
	l = val_int(len);
	sLen = val_strlen(data);
	c = val_int(chan);
	if( peer == NULL || c < 0 || c > 255 || pp < 0 || l < 0 || pp > sLen || pp + l > sLen )
			neko_error();
	packet = enet_packet_create(
		val_string(data) + pp,
		l,
		val_bool(reliable) ? ENET_PACKET_FLAG_RELIABLE : 0);
	if(enet_peer_send(peer, c, packet))
		neko_error();
	return alloc_int(l);
}

/**
        udpr_send_char : peer -> data:int -> chan:int -> reliable:bool -> void
        Send a character [ over a connected socket. Must be in the range 0..255</doc>
**/
static value udpr_send_char( value p, value data, value chan, value reliable ) {
	ENetPeer *peer;
	ENetPacket *packet;
	int c,d;
	char buf[2];
	val_check_kind(p,k_udprpeer);
	val_check(data,int);
	val_check(chan,int);
	val_check(reliable,bool);

	peer = (ENetPeer *)val_data(p);
	c = val_int(chan);
    d = val_int(data);

    if( peer == NULL || c < 0 || c > 255 || d < 0 || d > 255 )
        neko_error();
   	buf[0] = (unsigned char)d;
   	buf[1] = '\0';
	packet = enet_packet_create(
		buf,
		1,
		val_bool(reliable) ? ENET_PACKET_FLAG_RELIABLE : 0);
    if(enet_peer_send(peer, c, packet))
		neko_error();
    return val_true;
}


/**
	Flushes out all pending peer packets from a host. This happens
	automatically in enet_host_service(), but can be forced this way.
**/
static value udpr_flush(value h) {
	val_check_kind(h,k_udprhost);
	enet_host_flush( (ENetHost *)val_data(h) );
	return val_true;
}








/**
	Compares two peer pointers for equality. Returns bool
**/
static value udpr_peer_equal(value p, value p2) {
	val_check_kind(p,k_udprpeer);
	val_check_kind(p2,k_udprpeer);

#ifdef ENET_DEBUG
	fprintf(stderr, "udpr_peer_equal: comparing %x %x\n", (ENetPeer *)val_data(p), (ENetPeer *)val_data(p2));
#endif
	if((ENetPeer *)val_data(p) == (ENetPeer *)val_data(p2))
		return val_true;
	return val_false;
}

static value udpr_peer_address( value p ) {
	val_check_kind(p,k_udprpeer);
	ENetPeer* peer = (ENetPeer *)val_data(p);

	if(peer == NULL)
		neko_error();
    value rv = alloc_array(2);
    val_array_ptr(rv)[0] = alloc_int32(peer->address.host);
    val_array_ptr(rv)[1] = alloc_int(peer->address.port);
    return rv;
}

static value udpr_host_address( value h ) {
	val_check_kind(h,k_udprhost);
	ENetHost* host = (ENetHost *)val_data(h);

	if(host == NULL)
		neko_error();
    value rv = alloc_array(2);
    if(host->address.host != 0) {
    	val_array_ptr(rv)[0] = alloc_int32(host->address.host);
    	val_array_ptr(rv)[1] = alloc_int(host->address.port);
    }
    else {
    	struct sockaddr_in addr;
        unsigned int addrlen = sizeof(addr);
        if( getsockname(host->socket,(struct sockaddr*)&addr,&addrlen) == SOCKET_ERROR )
                neko_error();
        val_array_ptr(rv)[0] = alloc_int32(*(int*)&addr.sin_addr);
        val_array_ptr(rv)[1] = alloc_int(ntohs(addr.sin_port));
    }
    return rv;
}

/*
static value udpr_host_service (value h, value timeout)
{
	//ENetPeerHandle hndPeer = enet_host_peer_to_handle(host, event->peer);
	ENetHost *host;
	ENetPeerHandle hndPeer;
	//ENetPeer *peer;
    ENetEvent *event;
    int res;

	val_check_kind(h,k_udprhost);
	val_check(timeout,number);
	enet_uint32 tout = (enet_uint32)(val_number(timeout)*1000);

	host = (ENetHost *)val_data(h);
	event = (ENetEvent *) enet_malloc (sizeof (ENetEvent));
	res = enet_host_service (host, event, tout);

	if(res < 0) {
		printf("res %d\n", res);
		neko_error();
	}

	if(res > 0) {
		hndPeer = enet_host_peer_push_event(host, event, 0);
#ifdef ENET_DEBUG
	fprintf(stderr, "*** udpr_host_service: %d\n",hndPeer);
#endif
    	return alloc_int((int)hndPeer);
    }
    return val_null;
}
DEFINE_PRIM(udpr_host_service,2);
*/

static value udpr_get_peer_pointer(value h, value idx) {
	val_check_kind(h,k_udprhost);
	val_check(idx,int);
	ENetPeerHandle hndPeer = (ENetPeerHandle)val_int(idx);
	ENetPeer *peer = enet_host_handle_to_peer((ENetHost *)val_data(h), (ENetPeerHandle)val_int(idx));
	if(peer == NULL)
		neko_error();
	value v = alloc_abstract(k_udprpeer,peer);
	return v;
}
DEFINE_PRIM(udpr_get_peer_pointer,2);

static value udpr_get_peer_handle(value h, value p) {
//static value udpr_get_peer_handle(value p) {
	val_check_kind(h,k_udprhost);
	val_check_kind(p,k_udprpeer);

	ENetPeer *peer = (ENetPeer *)val_data(p);

	if((ENetPeer *)val_data(p) == NULL)
	//val_throw(alloc_string("pointer null"));
	neko_error();
	return alloc_int( peer -> incomingPeerID);
}
DEFINE_PRIM(udpr_get_peer_handle,2);



///////////////////////////////////////////////////////
//             EVENTS                                //
///////////////////////////////////////////////////////
/**
	Return a handle to a peer event. This does not have to be freed
**/
/*
static value udpr_event_get(value h, value pIdx) {
	ENetHost *host;
    ENetEvent *event;
	ENetPeerHandle hndPeer;

	val_check_kind(h,k_udprhost);
	val_check(pIdx,int);
    host = (ENetHost *)val_data(h);
	hndPeer = (ENetPeerHandle) val_int(pIdx);

	if(!PEER_HANDLE_VALID(host, hndPeer))
		//val_throw(alloc_string("udpr_get_event: invalid peer handle"));
		neko_error();
	event = enet_host_peer_pop_event(host, (ENetPeerHandle) val_int(pIdx));
	value e = alloc_abstract(k_udprevent, event);
	val_gc(e, destroy_enetevent);
	return e;
}
DEFINE_PRIM(udpr_event_get,2);
*/
/**
	Returns the channel associated with an event
**/
static value udpr_event_channel(value e) {
	val_check_kind(e,k_udprevent);
	ENetEvent *event = (ENetEvent *) val_data(e);
	//if(event == NULL)
	//	return alloc_int(-1);
	return alloc_int(event->channelID);
}
DEFINE_PRIM(udpr_event_channel,1);

/**
	Return a handle to a peer event. This does not have to be freed
**/
static value udpr_event_type(value e) {
	val_check_kind(e,k_udprevent);
	ENetEvent *event = (ENetEvent *) val_data(e);
	//ENetPeer *peer = (ENetPeer *)val_data(p);
	//if(peer == NULL)
		//return alloc_int(0);
	if(event == NULL)
		return alloc_int(0);
	switch(event->type) {
	case ENET_EVENT_TYPE_NONE:
		return alloc_int(0); break;
	case ENET_EVENT_TYPE_CONNECT:
		return alloc_int(1); break;
	case ENET_EVENT_TYPE_RECEIVE:
		return alloc_int(2); break;
	case ENET_EVENT_TYPE_DISCONNECT:
		return alloc_int(3); break;
	}
	return alloc_int(0);
}
DEFINE_PRIM(udpr_event_type,1);

/**
	Returns a copy of the data associated with an event
**/
static value udpr_event_data(value e) {
	val_check_kind(e,k_udprevent);
	ENetEvent *event = (ENetEvent *) val_data(e);
	//if(event == NULL)
		//return alloc_string("");
	switch(event->type) {
	case ENET_EVENT_TYPE_NONE:
		return alloc_string(""); break;
	case ENET_EVENT_TYPE_CONNECT:
		return alloc_string(""); break;
	case ENET_EVENT_TYPE_RECEIVE:
		if(event->packet != NULL)
			return copy_string((const char *) event->packet -> data,  event->packet->dataLength);
		return alloc_string("");
		break;
	case ENET_EVENT_TYPE_DISCONNECT:
		return alloc_string(""); break;
	}
	return alloc_string("");
}
DEFINE_PRIM(udpr_event_data,1);

static value udpr_event_peer_idx(value e) {
	val_check_kind(e,k_udprevent);
	ENetEvent *event = (ENetEvent *) val_data(e);
	if(e == NULL)
		//val_throw( alloc_string("NULL event pointer") );
		neko_error();
	return alloc_int(event -> peer -> incomingPeerID);
}
DEFINE_PRIM(udpr_event_peer_idx,1);

static value enumerate_ips() {
	value rv, cur = NULL, tmp;
	int c,x;
	int addr;

#ifdef NEKO_WINDOWS
	LPSOCKET_ADDRESS_LIST list = NULL;
	SOCKET s;
	int len = 0;
	char *buf = (char *)malloc(4096);

	s = socket(AF_INET, SOCK_RAW, IPPROTO_IP);
	if(s == SOCKET_ERROR)
		neko_error();

	c = WSAIoctl(s,
			SIO_ADDRESS_LIST_QUERY,
			NULL,
			0,
			buf,
			4096,
			(unsigned long *) &len,
			NULL,
			NULL);
	closesocket(s);

printf("iface count: %d\n", len);
	if(c == SOCKET_ERROR || len <=0) {
		free(buf);
		neko_error();
	}

	list = (LPSOCKET_ADDRESS_LIST) buf;
	if(list->iAddressCount <= 0) {
		free(buf);
		neko_error();
	}

	char sbuf[20];
	for(x=0; x < list->iAddressCount; ++x) {
		sprintf(sbuf, "inet%d", x);
		tmp = alloc_array(3);
		val_array_ptr(tmp)[0] = alloc_string(sbuf);
		memcpy(&addr, &list->Address[x].lpSockaddr->sa_data[2], 4);
		//(SOCKADDR_IN *)list.Address[x].lpSockaddr)->sin_addr
		val_array_ptr(tmp)[1] = alloc_int(addr);
		val_array_ptr(tmp)[2] = val_null;
		if( cur )
			val_array_ptr(cur)[2] = tmp;
		else
			rv = tmp;
		cur = tmp;
	}
	// insert the localhost record.
	if(list->iAddressCount > 0) {
		sprintf(sbuf, "inet%d", list->iAddressCount);
		tmp = alloc_array(3);
		val_array_ptr(tmp)[0] = alloc_string(sbuf);
		val_array_ptr(tmp)[1] = alloc_int(16777343);
		val_array_ptr(tmp)[2] = val_null;
		if( cur )
			val_array_ptr(cur)[2] = tmp;
		else
			rv = tmp;
		cur = tmp;
	}
	free(buf);
	return rv;
#else
	struct ifconf ifc;
	int s;
	int icnt = 10; // number of potential network interfaces.

	s = socket(AF_INET, SOCK_DGRAM,0);
	if(s < 0)
		neko_error();

	ifc.ifc_buf = NULL;
	while(1) {
		ifc.ifc_len = sizeof(struct ifreq) * icnt;
		ifc.ifc_buf = realloc(ifc.ifc_buf, ifc.ifc_len);
		if(ioctl(s, SIOCGIFCONF, &ifc) < 0) {
			close(s);
			free(ifc.ifc_buf);
			neko_error();
		}
		if(ifc.ifc_len == icnt * sizeof(struct ifreq)) {
			// may have more interfaces than we allowed for.
			icnt += 5;
			continue;
		}
		break;
	}

	rv = alloc_array(ifc.ifc_len/sizeof(struct ifreq));
	struct ifreq *ifr = ifc.ifc_req;
	//struct ifreq ifr2;
	for(x = 0, c = 0; x < ifc.ifc_len; x += sizeof(struct ifreq), c++) {
		if(ifr->ifr_addr.sa_family == AF_INET) {
			printf("x: %d c: %d name: %s\n", x, c, ifr->ifr_name);
			tmp = alloc_array(3);
			val_array_ptr(tmp)[0] = alloc_string(ifr->ifr_name);
			memcpy(&addr, &ifr->ifr_addr.sa_data[2],4);
			val_array_ptr(tmp)[1] = alloc_int(addr);
			val_array_ptr(tmp)[2] = val_null;
			if( cur )
				val_array_ptr(cur)[2] = tmp;
			else
				rv = tmp;
			cur = tmp;
		}
		ifr++;
	}

	close(s);
	free(ifc.ifc_buf);
	return rv;
#endif
}
DEFINE_PRIM(enumerate_ips,0);

/*


+    if (pollCount < 0) {
+       if(errno == EINTR)
+               return -2;

*/
///////////////////////////////////////////////////////
//             DEBUG                                 //
///////////////////////////////////////////////////////
/**
	Dump a peer address
**/
static value udpr_peer_pointer(value p) {
	val_check_kind(p,k_udprpeer);
	fprintf(stderr, "peer ptr: %x\n", (ENetPeer *)val_data(p));
	return val_true;
}
DEFINE_PRIM(udpr_peer_pointer,1);


DEFINE_PRIM(udpr_init,0);
DEFINE_PRIM(destroy_enetevent,1);
DEFINE_PRIM(udpr_bind,5);
DEFINE_PRIM(udpr_client_create,3);
DEFINE_PRIM(udpr_poll,2);
DEFINE_PRIM(udpr_setrate,3);
DEFINE_PRIM(udpr_max_peers,0);
DEFINE_PRIM(udpr_max_channels,0);
DEFINE_PRIM(udpr_write,4);
DEFINE_PRIM(udpr_send,6);
DEFINE_PRIM(udpr_send_char,4);
DEFINE_PRIM(udpr_flush,1);
DEFINE_PRIM(udpr_peer_equal,2);
DEFINE_PRIM(udpr_peer_address,1);
DEFINE_PRIM(udpr_host_address,1);
