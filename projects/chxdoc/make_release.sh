#!/bin/sh

VER=$(echo $1)
DIR=chxdoc_$(echo $VER | sed 's/\./_/g')

function prompt_continue {
	echo $1
	echo -n "Continue? [y/n] "
	read cont

	if [ !"$cont" = "y" ]; then
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


prompt_continue "Building release for $DIR"


mkdir -p chxdoc_release/Windows/$DIR
mkdir -p chxdoc_release/Linux/$DIR

#readme
sed 's/\n/\r\n/g' README > chxdoc_release/Windows/$DIR/README.txt
cp README chxdoc_release/Linux/$DIR/

#temploc
cp bin/Windows/temploc.exe chxdoc_release/Windows/$DIR/
cp bin/Linux/temploc chxdoc_release/Linux/$DIR/

#chxdoc
cp bin/Windows/chxdoc.exe chxdoc_release/Windows/$DIR/
cp bin/Linux/chxdoc chxdoc_release/Linux/$DIR/


#templates
cp -R templates chxdoc_release/Windows/$DIR/
cp -R templates chxdoc_release/Linux/$DIR/

cd chxdoc_release

#remove 'devel' template
rm -Rf Linux/$DIR/templates/devel
rm -Rf Windows/$DIR/templates/devel

#remove .svn directories
find . -name ".svn" -exec rm -Rf {} \; 2>/dev/null

#remove tmp files
find . -name "*~" -exec rm {} \;

cd Linux
tar -czf ${DIR}_linux.tgz $DIR
mv ${DIR}_linux.tgz ../

cd ../Windows
zip -rq $DIR $DIR
mv ${DIR}.zip ../${DIR}_win.zip

cd ../

echo "Complete. Files are in chxdoc_release."