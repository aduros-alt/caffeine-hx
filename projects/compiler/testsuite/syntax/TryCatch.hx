package syntax;

import unit.Assert;

import syntax.util.T;
import syntax.util.T2;
import syntax.util.ITest;

class TryCatch {
	public function new() {}
	
	public function testCatchInt() {
	  Assert.equals("Int", throwCatch(1));
	}
	
	public function testCatchFloat() {
	  Assert.equals("Float", throwCatch(0.1));
	}
	
	public function testCatchBool() {
	  Assert.equals("Bool", throwCatch(true));
	}
	
	public function testCatchString() {
	  Assert.equals("String", throwCatch("haXe"));
	}
	
	public function testCatchArray1() {
	  Assert.equals("Array", throwCatch([]));
	}
	
	public function testCatchArray2() {
	  Assert.equals("Array", throwCatch([1,2]));
	}
	public function testCatchSubClass() {
	  Assert.equals("T2", throwCatch(new T2()));
	}

	public function testCatchClass() {
	  Assert.equals("T", throwCatch(new T()));
	}	
	
	public function testCatchSubClassInterface() {
	  Assert.equals("ITest", throwCatchInterface(new T2()));
	}
	
	public function testCatchClassInterface() {
	  Assert.equals("ITest", throwCatchInterface(new T()));
	}
	
	public function testCatchDynamic() {
	  Assert.equals("Dynamic", throwCatch(Reflect.empty()));
	}	
	
	public function testCatchAll() {
	  Assert.equals("Dynamic", throwCatchInterface(1));
	}	
  
  public function testCatchWithOtherVarName() {
    try {
      throw "test";
      Assert.isTrue(false);
    } catch(myexception : String) {
      Assert.equals("test", myexception);
    }
  }
	
	function throwCatch(ex : Dynamic) {
	  try {
      throw ex;
	  } catch(e : Int) {
      return "Int";
	  } catch(e : Float) {
      return "Float";
	  } catch(e : Bool) {
      return "Bool";
	  } catch(e : String) {
      return "String";
	  } catch(e : Array<Dynamic>) {
      return "Array";
	  } catch(e : T2) {
      return "T2";
	  } catch(e : T) {
      return "T";
	  } catch(e : ITest) { // never reached
      return "ITest";
	  } catch(e : Dynamic) {
      return "Dynamic";
	  }
	  return null;
	}
	
	function throwCatchInterface(ex : Dynamic) {
	  try {
      throw ex;
	  } catch(e : ITest) {
      return "ITest";
	  } catch(e : Dynamic) {
      return "Dynamic";
	  }
	  return null;
	}
}