CHX_FILES=../../ext2/chx/Serializer.hx \
			../../ext2/chx/Unserializer.hx \
			../../ext2/chx/Log.hx

all: dependencies chxdoc

chxdoc: dummy
	haxe build.hxml

tests: test-developer test-user

test-developer: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc --policy allow --deny flash.utils --deny js.Boot --deny sys.db.* -o doc_developer --footerText="This is the <a href=\"http://www.haxe.org\" target=\"new\">footer link to haxe.org</a>" --tmpDir=__chxdoctmp --templatesDir=../src/templates --template=default --installTemplate=true --developer=true -f flash9.xml,flash9,flash -f neko.xml,neko -f js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

test-user: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_user --templatesDir=../src/templates --template=default --developer=false -f flash9.xml,flash,flash9 -f neko.xml,neko -f js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

test-web: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_web --templatesDir=../src/templates --template=default --developer=false -f flash9.xml,flash,flash9 -f neko.xml,neko -f js.xml,js --writeWebConfig
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

clean:
	cd test && $(RM) -R doc_developer
	cd test && $(RM) -R doc_user
	cd test && $(RM) -f *.swf *.n *.js *.xml
	rm -f make_release
	rm -Rf chxdoc_release
	rm -f chxdoc.n
	rm -rf __chxdoctmp

windows: dependencies dummy
	wine haxe build.hxml
	sh wine nekotools boot chxdoc.n

linux: dependencies dummy
	haxe build.hxml

release: dependencies make_release
	@if [ "${VER}" = "" ]; then echo "Set the VER var"; exit 1; fi;
	@./make_release $(VER)

make_release: make_release.sh

dependencies: $(CHX_FILES)
# 	cp $(CHX_FILES) src/chx/

install: chxdoc
	cp chxdoc ~/bin/

dummy:

