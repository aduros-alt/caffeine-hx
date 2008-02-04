package crypt;

class BasePhrase extends crypt.Base {
	public var passphrase(default,setPassphrase) : String;
        public function new(passphrase:String) {
                super();
		this.passphrase = passphrase;
        }

	function setPassphrase(s : String) {
		passphrase = s;
		return s;
	}
}

