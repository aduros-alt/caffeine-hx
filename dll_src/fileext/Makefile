include Makefile.config

NDLLS=fileext.ndll 
LIBPATH=-L/usr/lib
INCPATH=-I ./ -I /usr/include/neko -I ../include
LIBS=-L$(HOME)/neko/ -lneko

all: archtest $(NDLLS)

%.ndll: src/%.o
	$(CC) $(LIBPATH) $(INCPATH) -Wall -shared -o $@ $< $(LIBS)

src/%.o: src/%.c
	$(CC) -c $(INCPATH) -Wall -o $@ $<

install:
	@mv *.ndll ../../ext/ndll/$(ARCH_CAP)/

clean:
	@rm -f *.o
	@rm -f src/*.o
	@rm -f *.ndll

distclean: clean
	@rm -f ndll/Linux/*
	@rm -f ndll/Linux64/*
	@rm -f ndll/Windows/*
	@rm -f ndll/Mac/*
	@rm -f ndll/BSD/*

archtest:
	@if [ -z $(ARCH_CAP) ]; then \
		echo "You must specify the architecture to build for (make ARCH=?): "; \
		echo " ARCH: linux windows mac bsd wine"; \
		exit 1; \
	fi;

dummy:
