module haxe.FunctionBase;
import haxe.HaxeTypes;

private alias Dynamic DYN;

class FunctionBase {
	Dynamic opCall(Dynamic[] params) { return new Dynamic(); }
	Dynamic opCall() { return new Dynamic(); }
	Dynamic opCall(DYN a) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b,DYN c) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e,DYN f) { return new Dynamic(); }
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e,DYN f,DYN g) { return new Dynamic(); }
}

class Function(T) : FunctionBase {
	public T __fn;
	public this(T f) {
		__fn = f;
	}
	Function!(T) opAssign(T delegatePtr) {
		this.__fn = delegatePtr;
		return this;
	}
}

class Method : FunctionBase {
	void *__fn;
	public this(void *f) {
		this.__fn = f;
	}
	Dynamic opCall() { return cast(Dynamic)(cast(void * function()) __fn)(); }
}

/**
	A function takes a Class c to be used as "this", an array of
	parameters, and an object that contains context information, which
	can have fields set as a sort of closure.
**
alias Dynamic function(HaxeClass c, Dynamic[] params, HaxeObject context) Function;

/**
	Template for creating Dynamic methods from static functions.
	mixin(Method!("alias", "realfunction", context));
**
template Method(char[] name, char[] func, char[] context) {
	const char[] Method =
			"__fields[\""
			~ name ~
			"\"] = new DynamicFunction(this, &"
			~func~
			", "
			~context~
			");";
}
**/
