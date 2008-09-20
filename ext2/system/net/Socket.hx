package system.net;

#if neko
typedef Socket = neko.net.Socket;
typedef SocketInput = neko.net.SocketInput;
typedef SocketOutput = neko.net.SocketOutput;
#elseif php
typedef Socket = php.net.Socket;
typedef SocketInput = php.net.SocketInput;
typedef SocketOutput = php.net.SocketOutput;
#end