---
title: Nonce-based Freshness for Attestation in Certification Requests for use with the Certification Management Protocol

abbrev: Nonce-based Freshness in CMP
docname: draft-tschofenig-lamps-nonce-for-cmp-01
category: std

ipr: trust200902
area: Security
workgroup: LAMPS
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
author:
 -
      ins: H. Tschofenig
      name: Hannes Tschofenig
      email: hannes.tschofenig@siemens.com
      org: Siemens

 -
      ins: H. Brockhaus
      name: Hendrik Brockhaus
      email: hendrik.brockhaus@siemens.com
      org: Siemens


normative:
  RFC2119:
  I-D.ounsworth-csr-attestation:
  I-D.ietf-lamps-rfc4210bis:
  
informative:
  RFC9334:
  I-D.tschofenig-rats-psa-token:
  TPM20:
     author:
        org: Trusted Computing Group
     title: Trusted Platform Module Library Specification, Family 2.0, Level 00, Revision 01.59
     target: https://trustedcomputinggroup.org/resource/tpm-library-specification/
     date: November 2019

--- abstract

Certificate Management Protocol (CMP) defines protocol messages for
X.509v3 certificate creation and management. CMP provides interactions
between client systems and PKI components, such as a Registration
Authority (RA) and a Certification Authority (CA).

CMP allows an RA/CA to inform an end entity about the information
it has to provide in a certification request. When an end entity
places attestation information in form of evidence in a certification
signing request (CSR) it may need to demonstrate freshness of the
provided evidence. Attestation technology today often accomplishes
this task via the help of nonces. This document specifies how
nonces are provided by an RA/CA to the end entity for inclusion
in evidence.

--- middle

#  Introduction

Certificate Management Protocol (CMP) {{I-D.ietf-lamps-rfc4210bis}}
defines protocol messages for X.509v3 certificate creation and
management. CMP provides interactions between client systems and
PKI components, such as a Registration Authority (RA) and a
Certification Authority (CA).

CMP allows an RA/CA to inform an end entity about the information
it has to provide in a certification request. When an end entity
places attestation information in form of evidence in a
certification signing request (CSR) it may need to demonstrate
freshness of the provided evidence. Such an attestation extension
to a CSR is described in {{I-D.ounsworth-csr-attestation}}.
Attestation technology today, such as {{TPM20}} and
{{I-D.tschofenig-rats-psa-token}}, often accomplishes this task
via the help of nonces. A discussion of freshness approaches
for evidence is found in Section 10 of {{RFC9334}}.

For an end entity to include a nonce in the evidence (by the
attester) it is necessary to obtain this nonce from the relying
party, i.e. RA/CA in our use case, first. Since the CSR itself is
a 'one-shot' message the CMP protocol is used to obtain the nonce
from the RA/CA. CMP already offers a mechanism to request
information from the RA/CA prior to a certification request.
This document uses the CertReqTemplate described in
Section 5.3.19.16 of {{I-D.ietf-lamps-rfc4210bis}}. Once the nonce
is obtained the end entity can issue an API call to the attester
to request evidence and passes the nonce as an input parameter
into the API call. The returned evidence is then embedded into
a CSR and returned to the RA/CA in a certification request message.

This exchange is shown graphically below.

~~~
End entity                                          RA/CA
==========                                      =============

              -->>-- CertReqTemplate request -->>--
                                               Verify request
                                               Generate nonce*
                                               Create response
              --<<-- CertReqTemplate response --<<--
                     (nonce)
Generate key pair
Fetch Evidence (with nonce) from attester
Evidence Response from attestation
Creation of certification request
Protect request
              -->>-- certification request -->>--
                     (evidence including nonce)
                                               Verify request
                                               Verify evidence*
                                               Check replay*
                                               Issue certificate
                                               Create response
              --<<-- certification response --<<--
Handle response
Store certificate

*: These steps require interactions with a verifier.
~~~

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The terms attester, relying party, verifier and evidence are defined
in {{RFC9334}}.

We use the terms certification signing request (CSR) and certification
request interchangeably.

# Certificate Request Template Extension

The following structure defines the attestation nonce provided by the
CA/RA via a CertReqTemplate response message. This leads to an extra
roundtrip to convey the nonce to the end entity (and ultimately to
the attester functionality inside the device).

~~~
   id-ce-attestionNonce OBJECT IDENTIFIER ::=  { id-ce TBD }

   AttestationNonce ::= OCTET STRING
~~~

The end entity MUST construct a CertReqTemplate request message to trigger
the RA/CA to transmit a nonce.

When the RA/CA receive the CertReqTemplate
request message the profile information is used to determine that the
end entity supports attestation functionality. If the end-entity supports
attestation and the policy requires attestation information in a CSR to be
provided, the RA/CA issues a CertReqTemplate response containing a nonce in
in the template. The AttestationNonce MUST contain a random value that
depends on the used attestation technology. For example, the PSA attestation
token {{I-D.tschofenig-rats-psa-token}} supports nonces of length 32, 48
and 64 bytes. Other attestation technologies use nonces of similar length.
The assumption in this specification is that the RA/CA have out-of-band
knowledge about the required nonce length required for the technology used
by the end entity.

When the end entity receives the CertReqTemplate response it SHOULD use this
nonce as input to an attestation API call made to the attester functionality
on the device. The rational behind this design is that the design may support
attestation but configuration or policies make the attestation feature
unavailable. Hence, it is better for an RA/CA to be aggressive in sending
a nonce, at least where there is a reasonable chance the client supports
attestation and the client should be allowed to ignore the nonce if it either
does not support attestation or cannot use attestation for policy reasons.

While the semantic of the attestation API and the software/hardware
architecture is out-of-scope of this specification, the API will return
evidence from the attester in a format specific to the attestation technology
utilized. The encoding of the returned evidence varies but will be placed
inside the CSR, as specified in {{I-D.ounsworth-csr-attestation}}. The
software creating the CSR will not have to interpret the evidence format
- it is treated as an opaque blob. It is important to note that the
nonce is carried either implictily or explicitly in the evidence and
it MUST NOT be conveyed in elements of the CSR.

The processing of the CSR containing attestation information is described
in {{I-D.ounsworth-csr-attestation}}. Note that the CA MUST NOT issue
a certificate that contains the extension provided in the CertReqTemplate
containing the nonce. Instead the nonce is typically embedded in the
evidence and used as a way to provide freshness of the evidence provided
by the attester.

[Editor's Note: It may be useful to augment the CertReqTemplate request
with information about the type of attestation technology/technologies
available on the end entity. This is a topic for further discussion.]

#  IANA Considerations

TBD.

#  Security Considerations

This specification adds a nonce to the Certificate Request Template
for use with attestation information in a CSR. This specification
assumes that the nonce does not require confidentiality protection
without impacting the security property of the attestation protocol.
{{RFC9334}} defining the IETF remote attestation architecture
discusses this and other aspects in more detail.

For the use of attestation in the CSR the security considerations of
{{I-D.ounsworth-csr-attestation}} are relevant to this document.

#  Acknowledgments

We would like to thank Russ Housley and Carl Wallace for their review comments.
