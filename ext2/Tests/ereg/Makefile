all:
	haxe build.hxml
	haxe pytest.hxml

clean:
	$(RM) *.neko *.n *.swf *~ *.js

dependencyCheck:
	mkdir chx
	cp ../../chx/RegEx.hx chx/
	haxe -neko test.n -main Ereg -debug
	$(RM) -R chx
