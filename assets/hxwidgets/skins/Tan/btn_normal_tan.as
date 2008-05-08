package {
	import flash.display.Sprite;
	public class btn_normal_tan extends Sprite {
		[Embed(source="../Tan/button_normal.png")]
		private var i1:Class;
		public function btn_normal_tan() {
			addChild(new i1());
		}
	}
}
