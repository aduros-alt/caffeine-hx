package system.db;

#if php
typedef Connection = php.db.Connection;
#elseif neko
typedef Connection = neko.db.Connection;
#end