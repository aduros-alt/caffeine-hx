package tests;
import gd.Image;

class GdTest {
	public static function main() {
		var img1 = gd.Image.create(50,50);
		var fi = neko.io.File.read("tests/img_4213.jpg",true);
		var img2 = gd.Image.createFromJpeg(fi);
	}
}
