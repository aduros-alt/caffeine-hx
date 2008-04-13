package neutral.net;

#if php
typedef RemotingServer = php.net.RemotingServer;
#else neko
typedef RemotingServer = neko.net.RemotingServer;
#end