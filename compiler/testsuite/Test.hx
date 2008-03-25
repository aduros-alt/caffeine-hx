class Test {
  public static function main() {
	var runner = new unit.Runner();
	runner.register(syntax.AnonymousObject);
	runner.register(syntax.ArraySyntax);
	runner.register(syntax.Callback);
	runner.register(syntax.ClassInheritance);
	runner.register(syntax.CodeBlocks);
	runner.register(syntax.DynamicClass);
	runner.register(syntax.DynamicFunction);
	runner.register(syntax.EnumAccess);
	runner.register(syntax.EnumSyntax);
	runner.register(syntax.ForAccess);
	runner.register(syntax.IfAccess);
	runner.register(syntax.InterfaceAccess);
#if php
	runner.register(syntax.PhpDollarEscape);
	runner.register(syntax.PhpReservedWords);
#end
	runner.register(syntax.PrivateClassAccess);
	runner.register(syntax.PropertyAccess);
	runner.register(syntax.SwitchCaseAccess);
	runner.register(syntax.TryCatch);
	runner.register(syntax.TypedefAccess);
	runner.register(syntax.WhileAccess);
	runner.register(syntax.UnusualConstructs);

	// __resolve
	// __setfield
	// __unprotect__
	runner.run();
  }
}
