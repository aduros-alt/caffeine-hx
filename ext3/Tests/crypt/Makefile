HAXE=haxe
HAXECPP=haxelib run hxcpp
NMML=build.nmml
TARGETS:=$(shell cd src && ls *.hx | sed 's/.hx//g')
DEBUG=-debug # -D FIREBUG
COMMON=-cp ../../ -cp src $(DEBUG)

all:
	@echo Targets: `echo $(TARGETS)|sed 's/.hx / | /g'` "| clean"

$(TARGETS):
	$(HAXE) $(COMMON) $$FLAGS -cpp cpp -main $@
	$(HAXE) $(COMMON) $$FLAGS -swf test8.swf -swf-version 8 -main $@
	$(HAXE) $(COMMON) $$FLAGS -swf test9.swf -swf-version 9 -main $@
	$(HAXE) $(COMMON) $$FLAGS -js test.js -main $@
	$(HAXE) $(COMMON) $$FLAGS -neko test.n -main $@

.PHONY clean:
	@for t in $(TARGETS); do \
		echo "Cleaning $$t"; \
		rm -rf bin/$$t; \
	done
