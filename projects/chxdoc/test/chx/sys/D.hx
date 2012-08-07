package chx.sys;

@since("2008") class D {

	/** This is the comment for x, which has metadata 'values(-1,100)' **/
	@values(-1,100) static var x : Int;

	public static function myFunction<T>(parameter : T) : T {
		return null;
	}

	public static function myOtherFunction<T>(parameter : T) : T {
		return null;
	}

	public function new() {
	}

	/**
	 * This is the documentation for meta1
	 * @author Author tag value
	 **/
	@author("Russell") @debug public function meta1() {
	}
}
