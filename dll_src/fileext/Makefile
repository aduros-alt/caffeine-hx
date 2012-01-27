
all: dummy
	haxelib run hxcpp build.xml $(FLAGS)

install:
	@cp -f ndll/Linux/* ../../ext3/NDLL/Linux/
	@cp ndll/Linux64/* ../../ext3/NDLL/Linux64/
	@cp ndll/Windows/* ../../ext3/NDLL/Windows/
	@cp ndll/Mac/* ../../ext3/NDLL/Mac/
	@cp ndll/Mac64/* ../../ext3/NDLL/Mac64/
	@cp ndll/BSD/* ../../ext3/NDLL/BSD/

clean:
	@rm -f *.o
	@rm -f src/*.o
	@rm -rf obj
	@rm -f all_objs

distclean: clean
	@rm -f ndll/Linux/*
	@rm -f ndll/Linux64/*
	@rm -f ndll/Windows/*
	@rm -f ndll/Mac/*
	@rm -f ndll/Mac64/*
	@rm -f ndll/BSD/*

dummy:
