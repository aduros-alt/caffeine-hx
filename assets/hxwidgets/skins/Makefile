#	swfmill simple tan.xml hxwidgets_tan.swf
# HxwSkinAssetsTan

COMPC:=compc
MXMLC:=mxmlc

all: hxwidgets_tan.swf

hxwidgets_tan.swf: Tan/btn_normal_tan.as
	$(MXMLC) \
		-source-path=Tan \
		-includes \
			btn_over_tan \
			btn_normal_tan \
			btn_press_tan \
			cb_normal_tan \
			cb_checked_tan \
			rb_normal_tan \
			rb_checked_tan \
		-o $@ Tan/hxAssets.as

clean:
	rm -f hxwidgets_tan.swf

dummy:
