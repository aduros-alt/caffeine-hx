static function main() {
	var controller = new Controller("/", "module.Auth.login");
	controller.router.add("", module.Home, "index");
	controller.router.add("view/:user", module.Home, "viewUser");
	controller.registerEngine("text/html", loom.front.TemploEngine,
		[
			Web.getCwd()+"../mtt/",
			Web.getCwd()+"../tpl/",
			"macros/controller.macros.xml",
			true,
			{}
		], true);
		
		}
	controller.checkCredentials = function(requirement : String) {
		return true;
	};

	controller.execute();
}

// sample module
class Home extends Module {
	public function new();
	public function index() {
		return { message : "Hello World!" }
	}
	
	public function viewUser(user : Int) {
		// ...
	}
} 