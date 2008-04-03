class Test {
  public static function main() {
	var runner = new unit.Runner();
	runner.register(new syntax.AnonymousObject());
	runner.register(new syntax.ArraySyntax());
	runner.register(new syntax.Bitwise());
	runner.register(new syntax.Callback());
	runner.register(new syntax.ClassInheritance());
	runner.register(new syntax.CodeBlocks());
	runner.register(new syntax.DynamicClass());
	runner.register(new syntax.DynamicFunction());
	runner.register(new syntax.EnumAccess());
	runner.register(new syntax.EnumSyntax());
	runner.register(new syntax.ForAccess());
	runner.register(new syntax.IfAccess());
	runner.register(new syntax.InterfaceAccess());
#if php
	runner.register(new syntax.PhpDollarEscape());
	runner.register(new syntax.PhpReservedWords());
#end
	runner.register(new syntax.PrivateClassAccess());
	runner.register(new syntax.PropertyAccess());
	runner.register(new syntax.SwitchCaseAccess());
	runner.register(new syntax.TryCatch());
	runner.register(new syntax.TypedefAccess());
	runner.register(new syntax.WhileAccess());
	runner.register(new syntax.UnusualConstructs());
	
	runner.register(new stdlib.TestArray());
	runner.register(new stdlib.TestCompare());
	runner.register(new stdlib.TestDate());
	runner.register(new stdlib.TestEReg());
	runner.register(new stdlib.TestHash());
#if js
	runner.register(new stdlib.TestHtmlDom());
#end
	runner.register(new stdlib.TestHttp());
	runner.register(new stdlib.TestIntHash());
	runner.register(new stdlib.TestList());
	runner.register(new stdlib.TestMd5());
	runner.register(new stdlib.TestMisc());
#if neko
	runner.register(new stdlib.TestNekoSerialization());
#end
	runner.register(new stdlib.TestReflect());
	runner.register(new stdlib.TestSerialize());
	runner.register(new stdlib.TestStd());
	runner.register(new stdlib.TestString());
	runner.register(new stdlib.TestStringTools());
	runner.register(new stdlib.TestUnit());
	runner.register(new stdlib.TestXml());

	// __resolve
	// __setfield
	// __unprotect__
	runner.run();
  }
}
