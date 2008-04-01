package syntax;

import unit.Assert;

class Bitwise {
	public function testSHL() {
		Assert.equals(320, 5<<6);
	}

	public function testSHR() {
		Assert.equals(5, 320>>6);
		Assert.equals(5, 320>>>6);
	}

	public function testNegSHL() {
		Assert.equals(-2048,-512 << 2);
	}

	public function testNegSHR() {
		Assert.equals(2147483136, -1024 >>> 1);
		Assert.equals(-512, -1024 >> 1);
	}

	public function testXOR() {
		Assert.equals(481923, 25968 ^ 475123);
		Assert.equals(1023, 682 ^ 341);
	}

	public function testAND() {
		Assert.equals(1024, 1024 & 1024);
		Assert.equals(0x52, 0xFF52 & 0xFF);
		Assert.equals(0xFF00, 0xFF52 & 0xFF00);
	}

	public function testOR() {
		Assert.equals(1024, 1024 | 1024);
		Assert.equals(0xFFFF, 0xFF52 | 0xFF);
		Assert.equals(0xFF52, 0xFF52 | 0xFF00);
		Assert.equals(0xFF52, 0xFF00 | 0x52);
	}
}
