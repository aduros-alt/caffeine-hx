
tests: test-developer test-user

test-developer:
	cd test && haxe chx.hxml
	cd test && ../chxdoc -v -f flash.utils -f js.Boot -o doc_developer --footerText="This is the <a href=\"http://www.haxe.org\" target=\"new\">footer link to haxe.org</a>" --tmpDir=__chxdoctmp --templateDir=../templates/default --installTemplate=true --developer=true flash9.xml,flash9,flash neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

test-user:
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_user --tmpDir=__chxdoctmp --templateDir=../templates/default --installTemplate=true --developer=false flash9.xml,flash9,flash neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

clean:
	cd test && $(RM) -R doc_developer
	cd test && $(RM) -R doc_user
	cd test && $(RM) -f *.swf *.n *.js *.xml
	rm -f make_release
	rm -Rf chxdoc_release
	rm -f chxdoc.n

windows:
	wine haxe build.hxml

linux:
	haxe build.hxml

release: make_release
	@if [ "${VER}" = "" ]; then exit 1; fi;
	@./make_release $(VER)
	mv chxdoc.exe bin/Windows/
	mv chxdoc bin/Linux/

make_release: make_release.sh
