---
title: X.509-based Attestation Evidence
abbrev: X.509-based Attestation Evidence
docname: draft-ounsworth-rats-x509-evidence-00
category: std

ipr: trust200902
area: Security
workgroup: RATS
keyword: Internet-Draft

stand_alone: yes
pi:
  rfcedstyle: yes
  toc: yes
  tocindent: yes
  sortrefs: yes
  symrefs: yes
  strict: yes
  comments: yes
  inline: yes
  text-list-symbols: -o*+
  docmapping: yes
  toc_levels: 4

author:
    -
      ins: M. Ounsworth
      name: Mike Ounsworth
      org: Entrust Limited
      abbrev: Entrust
      street: 2500 Solandt Road – Suite 100
      city: Ottawa, Ontario
      country: Canada
      code: K2K 3G5
      email: mike.ounsworth@entrust.com

    -
      ins: H. Tschofenig
      name: Hannes Tschofenig
      org: Siemens
      email: hannes.tschofenig@gmx.net

normative:
  RFC2119:
  RFC9334:
  RFC5280:
  I-D.ietf-rats-eat:
  RFC9393:

informative:
  RFC2986:
  RFC4211:
  I-D.tschofenig-rats-psa-token:
  I-D.ietf-lamps-csr-attestation:
  IANA-Hash:
     author:
        org: IANA
     title: Hash Function Textual Names
     target: https://www.iana.org/assignments/hash-function-text-names
     date: 2023

--- abstract

This document specifies Claims for use within X.509 certificates. These
X.509 certificates are produced by an Attester as part of the remote
attestation procedures and consitute Evidence.

This document follows the Remote ATtestation procedureS (RATS)
architecture where Evidence is sent by an Attester and processed by
a Verifier.

--- middle

# Introduction

Trusted execution environments, like secure elements and hardware security
modules, are now widely used, which provide a safe environment to place
security sensitive code, such as cryptography, secure boot, secure storage,
and other essential security functions.  These security functions are
typically exposed through a narrow and well-defined interface, and can be
used by operating system libraries and applications.

When a Certificate Signing Request (CSR) library is requesting a certificate
from a Certification Authority (CA), a PKI end entity may wish to provide
Evidence of the security properties of the trusted execution environment
in which the private key is stored. This Evidence is to be verified by a
Relying Party, such as the Registration Authority or the Certification
Authority as part of validating an incoming CSR against a given certificate
policy. {{I-D.ietf-lamps-csr-attestation}} defines how to carry Evidence in
either PKCS#10 {{RFC2986}} or Certificate Request Message Format (CRMF)
{{RFC4211}}.

{{I-D.ietf-lamps-csr-attestation}} is agnostic to the content and the encoding
of Evidence. To offer interoperability it is necessary to define a format
that is utilized in a specific deployment environment environment.
Hardware security modules and other trusted execution environments, which
have been using ASN.1-based encodings for a long time prefer the use of
the same format throughout their software ecosystem. For those use cases
this specification has been developed.

This specification re-uses the claims defined in {{I-D.ietf-rats-eat}},
and encodes them as an extension in an X.509 certificate {{RFC5280}}.
While the encoding of the claims is different to what is defined in
{{I-D.ietf-rats-eat}}, the semantics of the claims is retained. This specification is not an EAP profile, as defined in Section 6 of {{I-D.ietf-rats-eat}}

This specification was designed to meet the requirements published by the CA Browser Forum to convey properties about hardware security models, such as non-exportability, which must be enabled for storing publicly-trusted code-signing keys. Hence, this specification is supposed to be used with the attestation extension for Certificate Signing Requests (CSRs), see
{{I-D.ietf-lamps-csr-attestation}}, but Evidence encoded as X.509 certificates
may also be used in other context.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

This document re-uses the terms defined in {{RFC9334}} related to remote
attestation. Readers of this document are assumed to be familiar with
the following terms: Evidence, Claim, Attestation Result, Attester,
Verifier, and Relying Party.

# Claims

## Nonce

The "nonce" claim is used to provide freshness.

The Nonce claim is used to carry the challenge provided by the caller to demonstrate freshness of the generated token. The following constraints apply to the nonce-type:

- The length MUST be either 32, 48, or 64 bytes.
- Only a single nonce value is conveyed.

The nonce claim is defined as follows:

~~~
   id-ce-evidence-nonce OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_nonce }

   claim_nonce ::= OCTET STRING
~~~

See Section 4.1 of {{I-D.ietf-rats-eat}} for a description of this claim.

##  Claims Describing the Entity

The claims in this section describe the entity itself.

###  ueid (Universal Entity ID) Claim

The "ueid" claim conveys a UEID, which identifies an individual manufactured entity. This identifier is a globally unique and permanent identifier. See Section 4.2.1 of {{I-D.ietf-rats-eat}} for a description of this claim. Three types of UEIDs are defined, which are distinguished via a type field.

The ueid claim is defined as follows:

~~~
   id-ce-evidence-ueid OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_ueid }

   claim_ueid ::= SEQUENCE {
       type    INTEGER ( RAND(1), EUI(2), IMEI(3),...),
       value   OCTET STRING
   }
~~~

##  sueids (Semi-permanent UEIDs) Claim (SUEIDs)

The "sueids" claim conveys one or more semi-permanent UEIDs (SUEIDs).
An SUEID has the same format, characteristics and requirements as a
UEID, but MAY change to a different value on entity life-cycle
events while the ueid claim is permanent. An entity MAY have both
a UEID and SUEIDs, neither, one or the other.

There MAY be multiple SUEIDs and each has a text string label the
purpose of which is to distinguish it from others. 

See Section 4.2.2 of {{I-D.ietf-rats-eat}} for a description of this claim.

The sueids claim is defined as follows:

~~~
   id-ce-evidence-sueids OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_sueids }

   claim_sueids ::= SEQUENCE {
       label   OCTET STRING,
       type    INTEGER ( RAND(1), EUI(2), IMEI(3),...),
       value   OCTET STRING
   }
~~~

## oemid (Hardware OEM Identification) Claim 

The "oemid" claim identifies the Original Equipment Manufacturer (OEM) of the hardware.

See Section 4.2.3 of {{I-D.ietf-rats-eat}} for a description of this claim.

The value of this claim depends on the type of OEMID and three types of IDs
are defined:

- OEMIDs using a 128-bit random number.
Section 4.2.3.1 of  {{I-D.ietf-rats-eat}} defines this type.

- an IEEE based OEMID using a global registry for MAC addresses and company IDs.
Section 4.2.3.1 of  {{I-D.ietf-rats-eat}} defines this type.

- OEMIDs using Private Enterprise Numbers maintained by IANA.
Section 4.2.3.3 of  {{I-D.ietf-rats-eat}} defines this type.

The oemid claim is defined as follows:

~~~
   id-ce-evidence-oemid OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_oemid }

   claim_oemid ::= SEQUENCE {
       type    INTEGER ( PEN(1), IEEE(2), RANDOM(3),...),
       value   OCTET STRING
   }
~~~

[Editor's Note: The value for the PEN is numeric. For the other
two types it is a binary string.]

## hwmodel (Hardware Model) Claim

The "hwmodel" claim differentiates hardware models, products and variants
manufactured by a particular OEM, the one identified by OEM ID.
It MUST be unique within a given OEM ID.  The concatenation of the OEM ID
and "hwmodel" give a global identifier of a particular product.
The "hwmodel" claim MUST only be present if an "oemid" claim is present.

See Section 4.2.4 of {{I-D.ietf-rats-eat}} for a description of this claim.

The hwmodel claim is defined as follows:

~~~
   id-ce-evidence-hwmodel OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_hwmodel }

   claim_hwmodel ::= OCTET STRING
~~~

##  hwversion (Hardware Version) Claim

The "hwversion" claim is a text string the format of which is set by each manufacturer. A "hwversion" claim MUST only be present if a "hwmodel" claim
is present.

See Section 4.2.5 of {{I-D.ietf-rats-eat}} for a description of this claim.

The hwversion claim is defined as follows:

~~~
   id-ce-evidence-hwversion OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_hwwversion }

   hwversion ::= OCTET STRING
~~~

## swversion (Software Version) Claim

The "swversion" claim makes use of the CoSWID version-scheme defined
in Section 4.1 of {{RFC9393}} to give a simple version for the software.
A "swversion" claim MUST only be present if a "swname" claim is present.

See Section 4.2.5 of {{I-D.ietf-rats-eat}} for a description of this claim.

The swversion claim is defined as follows:

~~~
   id-ce-evidence-swversion OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_swversion }

   swversion ::= PrintableString
~~~

## dbgstat (Debug Status) Claim

The "dbgstat" claim applies to entity-wide or submodule-wide debug
facilities and diagnostic hardware built into chips. It applies to
any software debug facilities related to privileged software that
allows system-wide memory inspection, tracing or modification of
non-system software like user mode applications.

See Section 4.2.9 of {{I-D.ietf-rats-eat}} for a description of this claim
and the semantic of the values in the enumerated list.

The dbgstat claim is defined as follows:

~~~
   id-ce-evidence-dbgstat OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_dbgstat }

   dbgstat ::= ENUMERATED {
      dsEnabled                   (0),
      disabled                    (1),
      disabledSinceBoot           (2),
      disabledPermanently         (3),
      disabledFullyAndPermanently (4)
   }
~~~

## software-component Claim

The Software Components claim is a list of software components that includes all the software (both code and configuration) loaded by the root of trust.

Each entry in the Software Components list describes one software component using the attributes described below:

- The Measurement Type attribute is short string representing the role of this software component. Examples include the bootloader code, the bootloader configuration, and firmware running in the Trusted Execution Environment.

- The Measurement Value attribute represents a hash of the invariant software component in memory at startup time. The value MUST be a cryptographic hash of 256 bits or stronger. For interoperability, SHA-256 is assumed to be the default.

- The Signer ID attribute is the hash of a signing authority public key for the software component. This can be used by a Verifier to ensure the components were signed by an expected trusted source.

- The Measurement Description contains the OID identifying the hash algorithm used to compute the corresponding Measurement Value. For interoperability, SHA-256 is the default. If the default algorithm is used, then this field can be omitted. The values for identifying the hash algorithms MUST be taken from [IANA-HASH].

The description of the software-component claims is taken from Section 4.4.1 of {{I-D.tschofenig-rats-psa-token}}

The software-component claim is defined as follows:

~~~
   id-ce-evidence-softwarecomponent OBJECT IDENTIFIER ::=
         { id-ce TBD_evidence TBD_softwarecomponent }

   softwarecomponent ::= SEQUENCE {
       measurement-type    PrintableString,
       measurement-value   OCTET STRING,
       signer-id           OCTET STRING,
       measurement-desc    OBJECT IDENTIFIER
   }

   softwarecomponents  ::=  SEQUENCE SIZE (1..MAX)
                            OF softwarecomponent
~~~

## fips_conf (Federal Information Processing Standards Conformance) Claim

TBD: Tomas/Mike to add text here. 

## cc_conf (Common Criteria Conformance) Claim

TBD: Tomas/Mike to add text here. 

# Security Considerations {#sec-cons}

This specification re-uses the claims from the EAT specification but
relies on the security protection offered by X.509 certificate and
particularly the digital signature covering the certificate. This
digital signature is computed with the Attestation Key available
on the device, see Section 12.1 of {{RFC9334}} for considerations
regarding the generation, the use and the protection of these
Attestation Keys. Although the encoding of an X.509 certificate
has been selected for conveying Claims from an Attester to a
Relying Party, this document uses a model that is very different
from Web PKI deployment where CAs verify whether an applicant
for a certificate legitimately represents the domain name(s) in the
certificate. Since the Attester located at the end entity creates
the X.509 certificate with claims defined in this document, it
conceptually acts like a CA. This document inherits the remote attestation architecture described in {{RFC9334}}. With the re-use of the claims
from {{I-D.ietf-rats-eat}} the security and privacy considerations
apply also to this document even though the encoding in this
specification is different from the encoding of claims discussed
by {{I-D.ietf-rats-eat}}.

Evidence contains information that may be unique to a device
and may therefore allow to single out an individual device for
tracking purposes.  Deployments that have privacy requirements must
take appropriate measures to ensure that claim values can only
identify a group of devices and that the Attestation Keys are used
across a number of devices as well.

To verify the Evidence, the primary need is to check the signature and
the correct encoding of the claims. To produce the Attestation Result,
the Verifier will use Endorsements, Reference Values, and Appraisal
Policies. The policies may require that certain claims must be present
and that their values match registered reference values.  All claims
may be worthy of additional appraisal.

#  IANA Considerations

TBD: OIDs for all the claims listed in this document.

--- back

# Acknowledgements

This specification is the work of a design team created by the chairs
of the LAMPS working group. This specification has been developed
based on discussions in that design team.

The following persons, in no specific order, contributed to the work:
Richard Kettlewell, Chris Trufan, Bruno Couillard, Jean-Pierre Fiset,
Sander Temme, Jethro Beekman, Zsolt Rózsahegyi, Ferenc Pető, Mike Agrenius Kushner, Tomas Gustavsson, Dieter Bong, Christopher Meyer, Michael StJohns, Carl
Wallace, Michael Ricardson, Tomofumi Okubo, Olivier Couillard, John
Gray, Eric Amador, Johnson Darren, Herman Slatman, Tiru Reddy, Thomas
Fossati, Corey Bonnel, Argenius Kushner, James Hagborg.

# A. Full ASN.1 {#full-asn1}

TBD: Full ASN.1 goes in here.
