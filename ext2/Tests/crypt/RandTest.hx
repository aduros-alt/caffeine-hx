import math.prng.Random;

class RandTest {
public static function main() {
	var rng = new math.prng.Random();
	for(x in 0...100)
		trace(rng.getByte());

	var bs = new ByteString();
	bs.setLength(256);
trace(bs.position);
trace(bs.length);
	rng.nextBytes(bs);

	trace(bs.toHex());
}

}
