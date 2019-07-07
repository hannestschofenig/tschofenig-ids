---
stand_alone: true
ipr: trust200902
docname: draft-tschofenig-core-senml-lbn-00
cat: std
updates: 8428
coding: utf-8
pi:
  strict: 'yes'
  toc: 'yes'
  tocdepth: '2'
  symrefs: 'yes'
  sortrefs: 'yes'
  compact: 'no'
  subcompact: 'no'
  comments: 'yes'
  inline: 'yes'
title: Introducing the Local Base Name in SenML
abbrev: SenML Local Base Name 
area: Applications Area (app)
wg: CORE
#date: 2019-06-18
author:
- ins: H. Tschofenig
  name: Hannes Tschofenig
  org: Arm Ltd.
  street: 110 Fulbourn Rd
  city: Cambridge
  code: CB1 9NJ
  country: UK
  email: Hannes.tschofenig@arm.com
  uri: http://www.tschofenig.priv.at
normative:
  RFC2119: bcp14
  RFC8428: RFC8428
  RFC8174: RFC8174
informative:
  RFC4122:
  LWM2M:
    title: Lightweight Machine to Machine Technical Specification Version 1.0
    target: http://www.openmobilealliance.org/release/LightweightM2M/V1_0-20170208-A/OMA-TS-LightweightM2M-V1_0-20170208-A.pdf
    author:
      org: Open Mobile Alliance
    date:  February 2017
    format:
      PDF: http://www.openmobilealliance.org/release/LightweightM2M/V1_0-20170208-A/OMA-TS-LightweightM2M-V1_0-20170208-A.pdf

--- abstract

The Sensor Measurement Lists (SenML) specification defines a format for representing simple sensor measurements and device parameters. This specification defines a new label to relax the requirement for global identification of every measurement.

--- middle

# Introduction {#introduction}

The Sensor Measurement Lists (SenML) specification, see RFC 8428 {{RFC8428}}, 
defines a format for representing simple sensor measurements and device parameters. 

Ideally, sensor readings used in the Internet of Things environment 
should be as small as possible. For this reason the specification 
also defines an encoding of these sensor measurements and device parameters 
in CBOR (on top of other serialization formats).

A design decision in SenML was, however, that each measurement transmitted 
over the network is self-contained and contains information that 
uniquely identifies and differentiates the sensor from all others - not only 
locally on the device but globally. 

This is accomplished by the combination of two fields, namely the 'Name' and 
the 'Base Name' values. The specification requires the concatenation of the 
Name and the Base Name values to yield the name of the sensor and 
recommends that the concatenated names be represented as URIs or URNs. 

{{fig-senml-example}} is an example taken from RFC 8428. 

~~~~
 [
    {"bn":"urn:dev:ow:10e2073a01080063:","n":"temp","u":"Cel","v":23.1},
    {"n":"label","vs":"Machine Room"},
    {"n":"open","vb":false},
    {"n":"nfc-reader","vd":"aGkgCg"}
 ]
~~~~
{: #fig-senml-example title='SenML Example Measurement with Base Name value'}

The global identification of every measurement as it is traveling through the 
network and through different systems has its use case and allows easy identification 
of the source and enables correlation.

Unfortunately, it also has drawbacks: 

* The unique identification of the sensor adds a substantial overhead, particularly when 
the sensor identification is verbose. Deployed systems, for example, make use of 
RFC 4122 {{RFC4122}} Type 5 Universally Unique IDentifier (UUIDs). 
   
* The global identification of every measurements is often unnecessary when the SenML 
is used as a mechanism to represent data for device-to-clould communication or cloud-to-gateway
communication where data is subsequently processed, aggregated or otherwise modified. 
In such systems, the identification of the sensor and the device has its origin in the 
security context rather than in the SenML contained measurment. LwM2M {{LWM2M}} is an 
example of such an architecture. 

* Finally, there are privacy implications of globally identifying each measurements and 
some deployments may prefer better privacy protection over ease of correlation. 

This specification therefore updates RFC 8428 and defines a new Local Base Name value (lbn) 
that can be used instead of the Base Name value defined in RFC 8428. 

{{fig-senml-lbn-example}} shows an example based on LwM2M use of SenML. 

~~~~
 [
    {"lbn":"/3303/", "n":"0/5700/", "v":25.2},
    {"n":"/1/5700/", "v":5}
 ]
~~~~
{: #fig-senml-lbn-example title='SenML Example Measurement with Local Base Name value'}

Note: In the LwM2M data model objects, object instances, and resources are encoded as numerical values. The value of '3303' refers to the Temperature object, '0' and '1' to the two instances of the resource '5700' (Sensor Value). 
Hence, this measurement indicates that the two temperator sensors expose their sensor readings.

# Terminology

   The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
   "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
   "OPTIONAL" in this document are to be interpreted as described in
   BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all
   capitals, as shown here.

   
# Local Base Name SenML Structure and Semantics 

This specification defines one new lable, the Local Base Name value, which is used instead of 
the Base Name value. For practical purposes the Local Base Name / Name concatination does not 
need to be a URN or a URI because existing data models used in the IoT space do not all make use 
of URIs/URNs. 

~~~~
 +-------------------+-------+------------+------------+------------+
 |          Name     | Label | CBOR Label | JSON Type  | XML Type   |
 +-------------------+-------+------------+------------+------------+
 | Local Base Name   | lbn   |          8 | String     | string     |
 +-------------------+-------+------------+------------+------------+
~~~~
 {: #fig-senml-lbn title='Local Base Name SenML Label'}


# CDDL

This document defines a new value to be added to the CDDL defined in Section 11 of RFC 8428. 

~~~~
The new key-value-pair is 

 lbn => tstr        ; Local Base Name
~~~~

# Security Considerations

This document inherits the security properties of RFC 8428 but improves its privacy features
by removing the unique identification of the sensor when the Local Base Name value is used 
instead of the Name / Base Name combination. 
     
# IANA Considerations

IANA is asked to register the following new entry in the SenML Labels Registry. 

~~~~
  +-----------------+-------+----+-----------+----------+----+--------------+
  |          Name   | Label | CL | JSON Type | XML Type | EI | Reference    |
  +-----------------+-------+----+-----------+----------+----+--------------+
  | Local Base Name | lbn   |  8 | String    | string   | a  |[[This RFC]]  |
  +-----------------+-------+----+-----------+----------+----+--------------+

                Note that CL = CBOR Label and EI = EXI ID.  
~~~~   

# Acknowledgements {#acknowledgements}

The author would like to thank the OMA Device Management and Service Enablement working group for their discussion 
and their input. In particular, I would to thank Ari Keranen, David Navarro, Mojan Mohajer and Alan Soloway.
