package haxe.io;

class StringOutput extends Output {
    var b : StringBuf;

    public function new() {
        b = new StringBuf();
    }

    public function writeChar(c) {
        b.addChar(c);
    }

    public override function writeBytes( buf : Bytes, bpos : Int, blen : Int ) : Int {
#if neko
        b.addSub( neko.Lib.stringReference( buf ), bpos, blen );
#else
        b.addSub( buf.toString(), bpos, blen );
#end
        return blen;
    }

    public function toString() {
        return b.toString();
    }
}
