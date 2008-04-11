package neutral.db;

#if php
typedef Transaction = php.db.Transaction;
#else neko
typedef Transaction = neko.db.Transaction;
#end