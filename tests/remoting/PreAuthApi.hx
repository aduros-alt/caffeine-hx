/**
	This is the client's available API before authentication.
**/
class PreAuthApi implements IServerApi {
	var client : ClientData;
	var attemptCount : Int;
	public function new(c : ClientData) {
		client = c;
		attemptCount = 0;
	}

	public function identify( name : String, pass : String ) : Void {
		if(!Std.is(name, String) || !Std.is(pass, String))
			throw "Invalid type";
		if(!ClientData.doAuth(client, name, pass)) {
			addAttempt();
			return;
		}
		return;
	}

	public function say( text : String ) : Void {
		throw "Not authenticated";
	}

	function addAttempt() {
		attemptCount++;
		if(attemptCount > 3) {
			CryptServer.trs.stopClient(client.adaptor.sc.getProtocol().socket);
		}
	}
}
