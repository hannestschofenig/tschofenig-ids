# XML2RFC=/Users/paul/Documents/xml2rfc-1.35/xml2rfc.tcl
XML2RFC=xml2rfc
UPLOADHOST=down.dsg.cs.tcd.ie

DATE=`date +%s`

all: core 

core:
	$(XML2RFC) draft-iab-iotsu-workshop-latest.xml draft-iab-iotsu-workshop-latest.txt

# This will only work if you have ssh setup on UPLOADHOST
upload:
	scp draft-iab-iotsu-workshop-latest.txt  $(UPLOADHOST):/var/www/misc/draft-iab-iotsu-workshop-latest.txt
	scp draft-iab-iotsu-workshop-latest.xml  $(UPLOADHOST):/var/www/misc/draft-iab-iotsu-workshop-latest.xml

backup:
	- mkdir backups
	cp draft-iab-iotsu-workshop-latest.txt backups/draft-iab-iotsu-workshop-latest-$(DATE).txt
	cp draft-iab-iotsu-workshop-latest.xml backups/draft-iab-iotsu-workshop-latest-$(DATE).xml

clean:
	rm -f   draft-iab-iotsu-workshop-latest-00.txt *~

