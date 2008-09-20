package system.db;

#if php
typedef Manager<T : Object> = php.db.Manager<T>;
#elseif neko
typedef Manager<T : Object> = neko.db.Manager<T>;
#end