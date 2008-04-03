package php;


class Sys {
	public static function time() : Float {
		return untyped __call__("time");
	}

	public static function cpuTime() : Float {
		return untyped __call__("microtime", true);
	}
}
