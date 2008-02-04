package crypt;

class BaseKeylen extends crypt.Base {
	public var keylen(default,setKeylen) : Int;

        public function new(keylen : Int) {
                super();
                this.keylen = keylen;
        }

        function setKeylen(len : Int) {
                keylen = len;
		return len;
        }

	function keyLengthError() {
		throw "Invalid key length";
	}
}
