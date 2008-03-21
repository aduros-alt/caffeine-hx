package unit;

import haxe.PosInfos;

class AssertException {
  public var pos : PosInfos;
  public var message : String;
  public function new(p : PosInfos, m : String) {
    pos = p;
	message = m;
  }
}