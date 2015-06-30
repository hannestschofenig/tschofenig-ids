OPEN=$(word 1, $(wildcard /usr/bin/xdg-open /usr/bin/open /bin/echo))

all: draft-tschofenig-core-coap-tcp-tls-02.txt

diff: all
	rfcdiff x draft-tschofenig-core-coap-tcp-tls-02.txt
	open draft-tschofenig-core-coap-tcp-tls-02.txt-from-x.diff.html

%.txt: %.xml
	xml2rfcv2 $<
	$(OPEN) $@

%.xml: %.mkd
	kramdown-rfc2629 $< >$@.new
	-diff $@ $@.new
	mv $@.new $@
	$(OPEN) $@
