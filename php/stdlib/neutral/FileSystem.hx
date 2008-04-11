package neutral;

#if php
typedef FileSystem = php.FileSystem;
#else neko
typedef FileSystem = neko.FileSystem;
#end