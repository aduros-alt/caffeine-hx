import math.IEEE754;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;

class IEEE754Test extends haxe.unit.TestCase {
	static var bigEndian : Bool = true;

	function verbose(type: String, value : Float, expectHex, result, resultHex) {
		return "Expected : " + Std.string(value) + " [" +expectHex + "] got "+ Std.string(result) + " [" + resultHex + "] for type " + type;
	}

	function performTest(value : Float, ?doTrace : Bool) {
		var bo = new BytesOutput();
		bo.bigEndian = bigEndian;
		bo.writeDouble(value);
		var expectHex = haxe.HexUtil.bytesToHex(bo.getBytes()).toUpperCase();

		var b = IEEE754.doubleToBytes(value, bigEndian);
		var bi = new BytesInput(b);
		bi.bigEndian = bigEndian;
		var result = bi.readDouble();
		var resultHex = haxe.HexUtil.bytesToHex(b).toUpperCase();
		var newValue = IEEE754.bytesToFloat(b, bigEndian);

		try {
			assertEquals(
				value,
				result
			);
		} catch(e:Dynamic) {
			if(	(Math.isNaN(value) && !Math.isNaN(result)) ||
				(value == Math.POSITIVE_INFINITY && result != Math.POSITIVE_INFINITY) ||
				(value == Math.NEGATIVE_INFINITY && result != Math.NEGATIVE_INFINITY) ||
				((expectHex != resultHex) && (IEEE754.splitFloat(value *10).integral != IEEE754.splitFloat(result *10).integral))
			) {
			#if neko
				e.error = verbose("Double", value, expectHex, result, resultHex);
				neko.Lib.rethrow(e);
			#else
				throw verbose("Double", value, expectHex, result, resultHex);
			#end
			}
		}
		if(doTrace)
			trace(verbose("Double", value, expectHex, result, resultHex));

		try {
			assertEquals(
				value,
				newValue
			);
		}
		catch(e:Dynamic) {
			if(	(Math.isNaN(value) && !Math.isNaN(newValue)) ||
				(value == Math.POSITIVE_INFINITY && newValue != Math.POSITIVE_INFINITY) ||
				(value == Math.NEGATIVE_INFINITY && newValue != Math.NEGATIVE_INFINITY)
			) {
			#if neko
				e.error = verbose("Float", value, expectHex, result, resultHex);
				neko.Lib.rethrow(e);
			#else
				throw verbose("Float", value, expectHex, result, resultHex);
			#end
			}
		}


		bo = new BytesOutput();
		bo.bigEndian = bigEndian;
		bo.writeFloat(value);
		expectHex = haxe.HexUtil.bytesToHex(bo.getBytes()).toUpperCase();

		b = IEEE754.floatToBytes(value, bigEndian);
		bi = new BytesInput(b);
		bi.bigEndian = bigEndian;
		result = bi.readFloat();
		resultHex = haxe.HexUtil.bytesToHex(b).toUpperCase();
		newValue = IEEE754.bytesToFloat(b, bigEndian);

		try {
			assertEquals(
				value,
				result
			);
		} catch(e:Dynamic) {
			if(	(Math.isNaN(value) && !Math.isNaN(result)) ||
				(value == Math.POSITIVE_INFINITY && result != Math.POSITIVE_INFINITY) ||
				(value == Math.NEGATIVE_INFINITY && result != Math.NEGATIVE_INFINITY) ||
				((expectHex != resultHex) && (IEEE754.splitFloat(value *10).integral != IEEE754.splitFloat(result *10).integral))
			) {
			#if neko
				e.error = verbose("Float", value, expectHex, result, resultHex);
				neko.Lib.rethrow(e);
			#else
				throw verbose("Float", value, expectHex, result, resultHex);
			#end
			}
		}
		if(doTrace)
			trace(verbose("Float", value, expectHex, result, resultHex));

		try {
			assertEquals(
				value,
				newValue
			);
		}
		catch(e:Dynamic) {
			if(	(Math.isNaN(value) && !Math.isNaN(newValue)) ||
				(value == Math.POSITIVE_INFINITY && newValue != Math.POSITIVE_INFINITY) ||
				(value == Math.NEGATIVE_INFINITY && newValue != Math.NEGATIVE_INFINITY)
			) {
			#if neko
				e.error = verbose("Float", value, expectHex, result, resultHex);
				neko.Lib.rethrow(e);
			#else
				throw verbose("Float", value, expectHex, result, resultHex);
			#end
			}
		}
	}
/*
	function testNegInfinity() {
		var value = Math.NEGATIVE_INFINITY;
		performTest(value);
	}

	function testPosInfinity() {
		var value = Math.POSITIVE_INFINITY;
		performTest(value);
	}

	function testNaN() {
		var value = Math.NaN;
		performTest(value);
	}

    function testSmall() {
        var value = -1.234;
		performTest(value);
	}

	function testMany() {
		var orig = -1.234;
        var value = -1.234;
		var cv = value;
		for(i in 0 ... 100) {
			performTest(value);
			value *= orig;
		}
    }
*/
    function testLarge() {
        var value = 1.234e43;
		performTest(value, true);
    }

}


class MathTest {
    static function main()
    {
#if !neko
        if(haxe.Firebug.detect()) {
            haxe.Firebug.redirectTraces();
        }
#end
		var r = new haxe.unit.TestRunner();
        r.add(new IEEE754Test());
        r.run();

	}
}
