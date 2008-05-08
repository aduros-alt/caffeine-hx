package {
	import flash.display.Sprite;
	public class cb_normal_tan extends Sprite {
		[Embed(source="../Tan/checkbox_normal.png")]
		private var i1:Class;
		public function cb_normal_tan() {
			addChild(new i1());
		}
	}
}
