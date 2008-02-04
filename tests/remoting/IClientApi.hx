
interface IClientApi {
	// login callbacks from server
	public function loginFailed() : Void;
	// success, startup crypting.
	public function startEncSession() : Void;

	////////////////////////////////////////
	//        Pre and Post login          //
	////////////////////////////////////////


	////////////////////////////////////////
	//           Post login               //
	////////////////////////////////////////

	public function userJoin( name : String ) : Void;
	public function userLeave( name : String ) : Void;
	public function userSay( name : String, text: String) : Void;

}
