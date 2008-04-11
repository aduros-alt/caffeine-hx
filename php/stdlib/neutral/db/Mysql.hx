package neutral.db;

#if php
typedef Mysql = php.db.Mysql;
#else neko
typedef Mysql = neko.db.Mysql;
#end