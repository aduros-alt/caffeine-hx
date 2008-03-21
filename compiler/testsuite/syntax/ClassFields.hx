package syntax;

import unit.Assert;

class ClassFields {
  public function new(){}
  private var _a : String;
  public var a : String;
  private function _b() { return "private"; }
  public function b() { return "public"; }
  static private var _c = "static private";
  static public var c = "static public";
  static private function _d() { return "static private"; }
  static public function d() { return "static public"; }
}