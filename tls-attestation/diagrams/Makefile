%.svg: %.txt ; aasvg < $< > $@

TXT_FILES := $(wildcard *.txt)
SVG_FILES := $(TXT_FILES:.txt=.svg)

svgs: $(SVG_FILES)

clean: ; $(RM) $(SVG_FILES)
