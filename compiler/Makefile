
all:
	ocaml install.ml

clean:
	find . -name "*~" -exec rm {} \;
	find . -name "*.cmi" -exec rm {} \;
	find . -name "*.cmx" -exec rm {} \;
	find . -name "*.o" -exec rm {} \;
	find . -name "*.a" -exec rm {} \;

short:
	cd haxe && ocamlopt -c -cclib -fno-stack-protector -I ../ocaml -I ../ocaml/swflib -I ../ocaml/xml-light -I ../ocaml/extc -I ../neko/libs/include/ocaml -pp camlp4o gendmd.ml main.ml
	cd haxe && ocamlopt -o ../bin/haxe ../ocaml/extLib.cmxa ../ocaml/extc/extc.cmxa ../ocaml/swflib/swflib.cmxa ../ocaml/xml-light/xml-light.cmxa unix.cmxa ast.cmx lexer.cmx type.cmx common.cmx parser.cmx typecore.cmx genxml.cmx typeload.cmx codegen.cmx typer.cmx ../neko/libs/include/ocaml/nast.cmx ../neko/libs/include/ocaml/binast.cmx ../neko/libs/include/ocaml/nxml.cmx genneko.cmx genas3.cmx genjs.cmx genswf8.cmx genswf9.cmx genswf.cmx genphp.cmx gendmd.cmx main.cmx
	cd bin && ./haxe build.hxml; nano outdir/Base.d

medium:
	cd haxe && ocamlopt -c -cclib -fno-stack-protector -I ../ocaml -I ../ocaml/swflib -I ../ocaml/xml-light -I ../ocaml/extc -I ../neko/libs/include/ocaml -pp camlp4o ast.ml lexer.ml type.ml common.ml parser.ml typecore.ml genxml.ml typeload.ml codegen.ml typer.ml ../neko/libs/include/ocaml/nast.ml ../neko/libs/include/ocaml/binast.ml ../neko/libs/include/ocaml/nxml.ml genneko.ml genas3.ml genjs.ml genswf8.ml genswf9.ml genswf.ml genphp.ml gendmd.ml main.ml
	cd haxe && ocamlopt -o ../bin/haxe ../ocaml/extLib.cmxa ../ocaml/extc/extc.cmxa ../ocaml/swflib/swflib.cmxa ../ocaml/xml-light/xml-light.cmxa unix.cmxa ast.cmx lexer.cmx type.cmx common.cmx parser.cmx typecore.cmx genxml.cmx typeload.cmx codegen.cmx typer.cmx ../neko/libs/include/ocaml/nast.cmx ../neko/libs/include/ocaml/binast.cmx ../neko/libs/include/ocaml/nxml.cmx genneko.cmx genas3.cmx genjs.cmx genswf8.cmx genswf9.cmx genswf.cmx genphp.cmx gendmd.cmx main.cmx
	cd bin && ./haxe build.hxml; nano outdir/Test.d

