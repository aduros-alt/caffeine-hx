package system.net;

#if neko
typedef Host = neko.net.Host;
#elseif php
typedef Host = php.net.Host;
#end