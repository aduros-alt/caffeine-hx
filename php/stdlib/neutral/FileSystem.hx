package neutral;

#if php
import php.FileSystem;
typedef FileStat   = php.FileStat;
typedef FileKind   = php.FileKind;
typedef FileSystem = php.FileSystem;
#else neko
import neko.FileSystem;
typedef FileStat   = neko.FileStat;
typedef FileKind   = neko.FileKind;
typedef FileSystem = neko.FileSystem;
#end