package {
	import flash.display.Sprite;
	public class btn_over_tan extends Sprite {
		[Embed(source="../Tan/button_over.png")]
		private var i1:Class;
		public function btn_over_tan() {
			addChild(new i1());
		}
	}
}
