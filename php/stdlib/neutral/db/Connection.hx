package neutral.db;

#if php
typedef Connection = php.db.Connection;
#else neko
typedef Connection = neko.db.Connection;
#end