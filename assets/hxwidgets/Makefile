#	swfmill simple tan.xml hxwidgets_tan.swf
# HxwSkinAssetsTan

COMPC:=compc
MXMLC:=mxmlc

all: tan

tan: dummy
	neko ../../as3libtool.n -i skins/Tan -o hxwidgets_tan.swf --build out --img-append _tan --mxmlc ~/bin/flex/bin/mxmlc

hxwidgets_tan.swf: skins/Tan/btn_normal_tan.as
	$(MXMLC) \
		-source-path=skins/Tan \
		-includes \
			btn_over_tan \
			btn_normal_tan \
			btn_press_tan \
			cb_normal_tan \
			cb_checked_tan \
			rb_normal_tan \
			rb_checked_tan \
			slider_one_tan \
			slider_one_over_tan \
		-o $@ skins/Tan/hxAssets.as

clean:
	rm -f hxwidgets_tan.swf
	rm -rf out

dummy:


