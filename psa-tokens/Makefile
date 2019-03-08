ID := draft-tschofenig-rats-psa-token

$(ID).txt: $(ID).xml
	xml2rfc -q $< -o $@

$(ID).xml: $(ID).md
	cat $< | kramdown-rfc2629 > $@

clean:
	$(RM) $(ID).xml $(ID).txt
