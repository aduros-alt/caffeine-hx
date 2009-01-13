
tests: test-developer test-user

test-developer:
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_developer --tmpDir=__chxdoctmp --templateDir=../templates/default --installTemplate=true --developer=true flash9.xml,flash9,flash neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js *.xml
	cd test && $(RM) -R __chxdoctmp

test-user:
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_user --tmpDir=__chxdoctmp --templateDir=../templates/default --installTemplate=true --developer=false flash9.xml,flash9,flash neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js *.xml
	cd test && $(RM) -R __chxdoctmp

clean:
	cd test && $(RM) -R doc_developer
	cd test && $(RM) -R doc_user
	rm -R chxdoc_release
