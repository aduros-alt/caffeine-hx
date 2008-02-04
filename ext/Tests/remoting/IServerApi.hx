/**
	These are the methods available on the server that the client can call.
**/
interface IServerApi {
	/** Authenticate to server **/
	public function identify( name : String, pass : String ) : Void;
	/** Crypt started. Join discussion **/
	public function join() : Void;
	/** Crypted text **/
	public function say( text : String ) : Void;
}
