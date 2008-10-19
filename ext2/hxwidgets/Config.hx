package hxwidgets;

class Config {

	public static var inst(default, null) : Config;

	function new() {
	}

	public dynamic function getTextFormat() {
		var fmt = new flash.text.TextFormat();
		fmt.font = "Times New Roman";
		fmt.color = 0x000000;
		fmt.size = 12;
		fmt.underline = false;
		return fmt;
	}

	static function __init__() {
		Config.inst = new Config();
	}
}
