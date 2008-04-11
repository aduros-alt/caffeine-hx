package neutral.db;

#if php
typedef Manager<T : Object> = php.db.Manager<T>;
#else neko
typedef Manager<T : Object> = neko.db.Manager<T>;
#end