# Validation of the XML instance documents from draft-ietf-ecrit-additional-data-30.txt

xmllint --noout EmergencyCallData.ProviderInfo.Example.xml --schema ProviderInfo.xsd
xmllint --noout EmergencyCallData.ServiceInfo.Example.xml --schema ServiceInfo.xsd
xmllint --noout EmergencyCallData.DeviceInfo.Example.xml --schema DeviceInfo.xsd
xmllint --noout EmergencyCallData.SubscriberInfo.Example.xml --schema SubscriberInfo.xsd
xmllint --noout EmergencyCallData.Comment.Example.xml --schema Comment.xsd

xmllint --noout Figure16-DeviceInfo.xml --schema DeviceInfo.xsd
xmllint --noout Figure16-ProviderInfo.xml --schema ProviderInfo.xsd

xmllint --noout Figure17-DataProviderContact.xml --schema ProviderInfo.xsd
xmllint --noout Figure17-DeviceInfo.xml --schema DeviceInfo.xsd
xmllint --noout Figure17-ProviderInfo-Client.xml --schema ProviderInfo.xsd
xmllint --noout Figure17-ProviderInfo-ServiceProvider.xml --schema ProviderInfo.xsd
xmllint --noout Figure17-ServiceInfo.xml --schema ServiceInfo.xsd

# xmllint --noout Figure18-PIDF-LO.xml --schema pidf.xsd geopriv10.xsd basicPolicy.xsd data-model.xsd
