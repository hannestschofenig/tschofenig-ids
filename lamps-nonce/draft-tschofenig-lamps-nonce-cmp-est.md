---
title: Nonce-based Freshness for Remote Attestation in Certificate Signing Requests (CSRs) for the Certification Management Protocol (CMP) and for Enrollment over Secure Transport (EST)

abbrev: Nonce Extension for CMP/EST
docname: draft-tschofenig-lamps-nonce-cmp-est-00
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
  I-D.ietf-lamps-csr-attestation:
  I-D.ietf-lamps-rfc4210bis:
  RFC8295:
  RFC7030:
  I-D.ietf-lamps-rfc7030-csrattrs:
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

Certificate Management Protocol (CMP) and Enrollment over Secure
Transport (EST) define protocol messages for X.509v3 certificate
creation and management. Both protocol provide interactions
between client systems and PKI components, such as a Registration
Authority (RA) and a Certification Authority (CA).

CMP and EST allow an RA/CA to inform an end entity about the information
it has to provide in a certification request. When an end entity
places attestation Evidence in a Certificate Signing Request (CSR)
it may need to demonstrate freshness of the provided Evidence.
Attestation technology today often accomplishes this task via the
help of nonces.

This document specifies how nonces are provided by an RA/CA to
the end entity for inclusion in evidence.

--- middle

#  Introduction

Certificate Management Protocol (CMP) {{I-D.ietf-lamps-rfc4210bis}}
defines protocol messages for X.509v3 certificate creation and
management. CMP provides interactions between client systems and
PKI components, such as a Registration Authority (RA) and a
Certification Authority (CA). Enrollment over Secure Transport
(EST) {{RFC7030}} is another popular protocol for the management
of certificates, which provides a sub-set of the features offered
by CMP.

Both protocols allow an RA/CA to inform an end entity about the
information it has to provide in a certification request. When an
end entity places attestation Evidence in a Certificate Signing
Request (CSR) it may need to demonstrate freshness of the provided
Evidence. This extension to a CSR is described in
{{I-D.ietf-lamps-csr-attestation}}. Attestation technology today,
such as {{TPM20}} and {{I-D.tschofenig-rats-psa-token}}, often
accomplishes this task via the help of nonces. A discussion of
freshness approaches for Evidence is found in Section 10 of
{{RFC9334}}.

To include a nonce in Evidence by the Attester at the an end entity
it is necessary to obtain this nonce from the Relying
Party, i.e. RA/CA in our use case, first. Since the CSR itself is
a 'one-shot' message the CMP/EST protocols are used to obtain the
nonce from the RA/CA.

CMP already offers a mechanism to request
information from the RA/CA prior to a certification request.
The same is true for EST. 

Once the nonce
is obtained the end entity can issue an API call to the Attester
to request Evidence and passes the nonce as an input parameter
into the API call. The returned Evidence is then embedded into
a CSR and returned to the RA/CA in a certification request message.

The main functionality of this document is described in three
sections, namely: 

- {{CMP}} describes how to convey the nonce CMP,
- {{EST}} offers the equivalent functionality for EST, and
- {{asn.1}} contains the ASN.1 description. 

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The terms Attester, Relying Party, Verifier and Evidence are defined
in {{RFC9334}}.

We use the terms certification signing request (CSR) and certification
request interchangeably.

# Conveying a Nonce in CMP {#template}

Section 5.3.19.16 of {{I-D.ietf-lamps-rfc4210bis}} defines the
Certificate Request Template (CertReqTemplate) message for use with CMP.
The CertReqTemplateContent payload, which is sent by the CA/RA in
response to a request message by the end entity, contains the nonce.
The use of the Certificate Request Template request/response message
exchange leads to an extra roundtrip to convey the nonce from the
CA/RA to the end entity (and ultimately to the Attester inside the device).

The end entity MUST construct a CertReqTemplate request message to trigger
the RA/CA to transmit a nonce in the response.

When the RA/CA receive the CertReqTemplate request message the profile
information is used to determine that the end entity supports this
specification as well as {{I-D.ietf-lamps-csr-attestation}}. If the
end entity supports remote attestation and the policy requires Evidence
in a CSR to be provided, the RA/CA issues a CertReqTemplate response
containing a nonce in in the template.

The following exchange showns the interaction graphically.

~~~
End Entity                                          RA/CA
==========                                      =============

              -->>-- CertReqTemplate request -->>--
                                               Verify request
                                               Generate nonce*
                                               Create response
              --<<-- CertReqTemplate response --<<--
                     (nonce)
Generate key pair
Fetch Evidence (with nonce) from Attester
Evidence response from Attester
Generate certification request message
Protect request
              -->>-- certification request -->>--
                     (Evidence including nonce)
                                               Verify request
                                               Verify Evidence*
                                               Check for replay*
                                               Issue certificate
                                               Create response
              --<<-- certification response --<<--
Handle response
Store certificate

*: These steps require interactions with a Verifier.
~~~


# Conveying a Nonce in EST {#EST}

EST offers two ways an EST server can use to tell the EST client what
values to use in a CSR. These two approaches are described

- in Section 4.5.2 of {{RFC7030}}, and
- in Appendix B of {{RFC8295}}. 

The latter functionality corresponds to the use of CSR templates in {{CMP}}. While
this approach is preferred, an EST deployment may only support RFC 7030
functionality and for this reason a CSR attribute to convey a nonce
is defined. {{I-D.ietf-lamps-rfc7030-csrattrs}} offers additional
clarifications for use of CSR attributes in Section 3.2.


# Nonce Processing Guidelines

When the RA/CA is requested or configured to transmit a nonce to an
end entity then it interacts with the Verifier.
The Verifier is, according to the IETF RATS architecture {{}}, "a role
performed by an entity that appraises the validity of Evidence about
an Attester and produces Attestation Results to be used by a Relying
Party." Since the Attester validates Evidence it is also the source
of the nonce, at least indirectly, to check for replay.

Once the nonce is available to the RA/CA, the nonce MUST be copied to
the EvidenceNonce field. It MUST contain a random byte sequence whereby
the length depends on the used
remote attestation technology. For example, the PSA attestation
token {{I-D.tschofenig-rats-psa-token}} supports nonces of length 32, 48
and 64 bytes. Other attestation technologies use nonces of similar length.
The assumption in this specification is that the RA/CA have out-of-band
knowledge about the required nonce length required for the attestation
technology used by the end entity.

When the end entity receives the nonce it SHOULD use it as input to an
attestation API call made to the Attester on the device. The rational
behind this "SHOULD"-requirement, rather than a "MUST"-requirement, is
that the end entity may support remote attestation but configuration
or policies make it unavailable. Hence, it is better for an RA/CA to be
aggressive in sending a nonce, at least where there is a reasonable
chance the client supports remote attestation and the client should be
allowed to ignore the nonce if it either does not support it or cannot
use it for policy reasons.

While the semantic of the attestation API and the software/hardware
architecture is out-of-scope of this specification, the API will return
Evidence from the Attester in a format specific to the attestation technology
utilized. The encoding of the returned evidence varies but will be placed
inside the CSR, as specified in {{I-D.ietf-lamps-csr-attestation}}. The
software creating the CSR will not have to interpret the Evidence format
- it is treated as an opaque blob. It is important to note that the
nonce is carried in the Evidence, either implictily or explicitly, and
it MUST NOT be conveyed in elements of the CSR.

The processing of the CSR containing Evidence is described
in {{I-D.ietf-lamps-csr-attestation}}. Note that the issued certificates
does not contain the nonce, as explained in
{{I-D.ietf-lamps-csr-attestation}}. Instead, it is typically
embedded in the Evidence and used as a way to provide freshness of the
Evidence signed by the Attester.

#  IANA Considerations

[Editor's Note: The ASN.1 module OID (TBD2) and the new private
extension (TBD1) must be registered.]

#  Security Considerations

This specification adds a nonce to a Certificate Request Message Format
(CRMF) extension and to PKCS#10 attribute. This specification
assumes that the nonce does not require confidentiality protection
without impacting the security property of the remote attestation protocol.
{{RFC9334}} defines the IETF remote attestation architecture
discusses nonce-based freshness in more detail.

For the use of Evidence in the CSR the security considerations of
{{I-D.ietf-lamps-csr-attestation}} are relevant to this document.

# ASN.1 Definitions {#asn.1}

~~~
PKIX-CMP-KeyAttestationNonceExtn-2023
  { iso(1) identified-organization(3) dod(6) internet(1) security(5)
    mechanisms(5) pkix(7) id-mod(0) id-mod-evidenceNonce(TBD2) }

DEFINITIONS IMPLICIT TAGS ::= BEGIN

IMPORTS
  id-pe
    FROM PKIX1Explicit-2009 -- from [RFC5912]
      { iso(1) identified-organization(3) dod(6) internet(1) security(5)
         mechanisms(5) pkix(7) id-mod(0) id-mod-pkix1-explicit-02(51) }
  EXTENSION
    FROM PKIX-CommonTypes-2009  -- From RFC 5912
      { iso(1) identified-organization(3) dod(6) internet(1) security(5)
        mechanisms(5) pkix(7) id-mod(0) id-mod-pkixCommon-02(57) } ;


id-pe-evidenceNonce OBJECT IDENTIFIER ::= { id-pe TBD1 }

EvidenceNonce ::= OCTET STRING

--
-- Evidence Nonce Attribute
--

-- For PKCS#10
attr-evidence ATTRIBUTE ::= {
  TYPE EvidenceNonce
  IDENTIFIED BY id-pe-evidenceNonce
}

--
-- Evidence Nonce Extension
--

-- For CRMF
ext-evidenceNonce EXTENSION ::= {
  TYPE EvidenceNonce
  IDENTIFIED BY id-pe-evidenceNonce
}

END

~~~


--- back

# Open Issues

It may be useful to inform the CA/RA about the type of attestation
technology/technologies available on the end entity.


# Acknowledgments

We would like to thank Russ Housley and Carl Wallace for their review comments.
