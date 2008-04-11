package neutral.db;

#if php
typedef ResultSet = php.db.ResultSet;
#else neko
typedef ResultSet = neko.db.ResultSet;
#end