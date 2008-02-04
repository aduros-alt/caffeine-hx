package crypt;

class BaseKeylenPhrase extends crypt.BaseKeylen {
	public var passphrase(default,setPassphrase) : String;
        public function new(keylen : Int, passphrase:String) {
                super(keylen);
		this.passphrase = passphrase;
        }

	function setPassphrase(s : String) {
		passphrase = s;
		return s;
	}
}

