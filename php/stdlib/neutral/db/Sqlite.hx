package neutral.db;

#if php
typedef Sqlite = php.db.Sqlite;
#else neko
typedef Sqlite = neko.db.Sqlite;
#end