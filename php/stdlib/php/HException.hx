package php;

extern class HException {
  public var e : Dynamic;
  public var p : haxe.PosInfos;
  public function new(e : Dynamic, ?message : String, ?code : Int, ?p : haxe.PosInfos) : Void;
  public function setLine(l:Int) : Void;
  public function setFile(f:String) : Void;
  
  var line : Int;
  var file : String;
  
  public function getMessage() : String;       // message of exception 
  public function getCode() : Int;             // code of exception
  public function getFile() : String;          // source filename
  public function getLine() : Int;             // source line
  public function getTrace() : Array<String>;  // an array of the backtrace()
  public function getTraceAsString() : String; // formated string of trace
}

/*
class HException extends Exception {
  public var e : Dynamic;
  public var p : haxe.PosInfos;
  public function new(e : Dynamic, ?message : String, ?code : Int, ?p : haxe.PosInfos) {
    super(message, code);
	this.e = e;
	this.p = p;
  }
  
  public function setLine(l:Int) {
    line = l;
  }
  
  public function setFile(f:String) {
    file = f;
  }
}
*/