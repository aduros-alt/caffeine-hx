package haxe.io;

class StringOutput extends Output {
    var b : StringBuf;

    public function new() {
        b = new StringBuf();
    }

    public override function writeChar(c) {
        b.addChar(c);
    }

    public override function writeBytes( buf, bpos, blen ) : Int {
        b.addSub(buf,bpos,blen);
        return blen;
    }

    public function toString() {
        return b.toString();
    }
}
