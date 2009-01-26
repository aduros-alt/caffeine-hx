

class TestEReg {

	public static function main() {
		trace("EReg test");
		var ereg = new EReg("able", "i");

		try {
			trace(ereg.match("I am able to do that"));
			trace(ereg.matched(0));
			trace(ereg.matchedLeft());
			trace(ereg.matchedRight());
		} catch(e:Dynamic) {
			trace(e);
		}
	}
}
