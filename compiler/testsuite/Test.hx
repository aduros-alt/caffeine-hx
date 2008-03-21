class Test {
  public static function main() {
	var runner = new unit.Runner();
	runner.register(syntax.AnonymousObject);
	runner.register(syntax.ArraySyntax);
	runner.register(syntax.BlockScope);
	runner.register(syntax.Callback);
	runner.register(syntax.ClassConstructorArguments);
	runner.register(syntax.ClassFields);
	runner.register(syntax.ClassInheritance);
	runner.register(syntax.ClassNoConstructor);
	runner.register(syntax.CodeBlockAssignament);
	runner.register(syntax.EnumAccess);
	runner.register(syntax.ForAccess);
	runner.register(syntax.FunctionDereference);
	runner.register(syntax.FunctionRedefinition);
	runner.register(syntax.IfAccess);
	runner.register(syntax.ImplementsDynamic);
	runner.register(syntax.ImplementsDynamicT);
	runner.register(syntax.InlineFunction);
	runner.register(syntax.InterfaceAccess);
	runner.register(syntax.MultipleImplementsDynamic);
	runner.register(syntax.ReservedWords);
	runner.register(syntax.PrivateClassAccess);
	runner.register(syntax.StringSyntax);
	runner.register(syntax.SuperAccess);
	runner.register(syntax.SwitchCaseAccess);
	runner.register(syntax.TypedefAccess);
	runner.register(syntax.WhileAccess);  
	runner.run();
  }
}
