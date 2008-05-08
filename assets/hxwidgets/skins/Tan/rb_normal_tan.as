package {
	import flash.display.Sprite;
	public class rb_normal_tan extends Sprite {
		[Embed(source="../Tan/radio_normal.png")]
		private var i1:Class;
		public function rb_normal_tan() {
			addChild(new i1());
		}
	}
}
