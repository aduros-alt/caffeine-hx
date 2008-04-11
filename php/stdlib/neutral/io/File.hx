package neutral.io;

#if php
typedef File = php.io.File;
#else neko
typedef File = neko.io.File;
#end