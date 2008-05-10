package {
	import flash.display.Sprite;
	public class slider_one_tan extends Sprite {
		[Embed(source="../Tan/slider_one_tan.png")]
		private var i1:Class;
		public function slider_one_tan() {
			addChild(new i1());
		}
	}
}
