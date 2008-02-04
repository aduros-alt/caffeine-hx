/**
	This is the client's available API after authentication has occurred.
**/
class PostAuthApi implements IServerApi {
	var client : ClientData;

	public function new(c : ClientData) {
		client = c;
	}

	public function identify( name : String, pass : String ) : Void {
		throw "Already authenticated";
	}

	public function say( text : String ) : Void {
		if(!Std.is(text, String))
			throw "Invalid type";

		for( c in CryptServer.clients )
			c.api.userSay(client.name, text);
	}
}