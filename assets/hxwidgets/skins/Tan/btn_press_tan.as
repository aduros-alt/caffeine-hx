package {
	import flash.display.Sprite;
	public class btn_press_tan extends Sprite {
		[Embed(source="../Tan/button_press.png")]
		private var i1:Class;
		public function btn_press_tan() {
			addChild(new i1());
		}
	}
}
