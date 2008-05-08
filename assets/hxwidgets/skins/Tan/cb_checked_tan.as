package {
	import flash.display.Sprite;
	public class cb_checked_tan extends Sprite {
		[Embed(source="../Tan/checkbox_checked.png")]
		private var i1:Class;
		public function cb_checked_tan() {
			addChild(new i1());
		}
	}
}
