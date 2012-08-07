#!/bin/sh

set -e

VER=$(echo $1)
DIR=chxdoc_$(echo $VER | sed 's/\./_/g')
VERSION=$(echo $VER | sed 's/\./_/g')

function prompt_continue {
	echo $1
	echo -n "Continue? [y/n] "
	read cont

	if [ ! "$cont" = "y" ]; then
		exit 0
	fi;
}

if [ ! -n "$VER" ]; then
	echo "Add a release number (eg. 0.5) to the command line"
	exit 1
fi;



if [ -e chxdoc_release ]; then
	prompt_continue "This will remove an existing chxdoc_release directory";
	rm -Rf chxdoc_release
fi;

echo "NOTE: Due to a hang in wine when using nekotools, you must 'make windows' before continuing"
echo "Make sure src/haxelib.xml and src/chxdoc/ChxDocMain.hx have their version numbers changed"
prompt_continue "Building release for $DIR"

make linux
#make windows

echo "Creating directories"
mkdir -p chxdoc_release/Windows/$DIR
mkdir -p chxdoc_release/Linux/$DIR

echo "Installing src"
cp -r src chxdoc_release/

#readme
echo "Updating READMEs"
sed 's/\n/\r\n/g' src/README > chxdoc_release/Windows/$DIR/README.txt
cp src/README chxdoc_release/Linux/$DIR/

#chxdoc
echo "Installing windows binary"
mv chxdoc.exe chxdoc_release/Windows/$DIR/ || {
	echo "You did not run 'make windows' before release"
	exit 1;
}
echo "Installing linux binary"
mv chxdoc chxdoc_release/Linux/$DIR/


#templates
echo "Installing templates to binary distros"
cp -R src/templates chxdoc_release/Windows/$DIR/
cp -R src/templates chxdoc_release/Linux/$DIR/

cd chxdoc_release

echo "Cleaning distribution"

set +e

#remove .svn directories in chxdoc_release
find . -name ".svn" -exec rm -Rf {} \; 2>/dev/null

#remove tmp files in chxdoc_release
find . -name "*~" -exec rm {} \;

set -e

#make the haxelib version
echo "Creating haxelib tools"
cd src/Tools
haxe build.hxml
cd ../
zip -r ../chxdoc_lib-${VERSION} *
cd ..
haxelib test chxdoc_lib-${VERSION}.zip

echo "Packaging linux distribution"
cd Linux
tar -czf ${DIR}_linux.tgz $DIR
mv ${DIR}_linux.tgz ../

echo "Packaging windows distribution"
cd ../Windows
zip -rq $DIR $DIR
mv ${DIR}.zip ../${DIR}_win.zip

cd ../../

pwd
rm chxdoc.n

echo "Complete. Files are in chxdoc_release."
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Make sure to test the haxelib version now with"
echo "haxelib run chxdoc install ~/bin"

