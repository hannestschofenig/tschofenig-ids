---
title: Nonce-based Freshness for Attestation in Certification Requests for use with the Certification Management Protocol

abbrev: Nonce-based Freshness in CMP
docname: draft-brockhaus-lamps-nonce-for-cmp-00
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
      ins: H. Brockhaus
      name: Hendrik Brockhaus
      email: hendrik.brockhaus@siemens.com
      org: Siemens

 -
      ins: H. Tschofenig
      name: Hannes Tschofenig
      email: hannes.tschofenig@siemens.com
      org: Siemens

normative:
  RFC2119:
  RFC8174:
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
a “one-shot” message the CMP protocol is used to obtain the nonce
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

  Request key generation
                -->>-- CertReqTemplate request -->>--
                                                 Verify request
                                                 Generate nonce
                                                 Create response
                --<<-- CertReqTemplate response --<<--
                       (nonce) 
  Request Evidence (nonce)
  Evidence Response
  Creation of certification request
  Protect request with IAK
                -->>-- certification request -->>--
                       (evidence including nonce)
                                                 Verify request
                                                 Process request
                                                 Verify evidence
                                                 Create response
                --<<-- certification response --<<--
  Handle response
  Create confirmation
                -->>-- cert conf message      -->>--
                                                 Verify confirmation
                                                 Create response
                --<<-- conf ack (optional)    --<<--
  Handle response
~~~

# Certificate Request Template Extension

This section defines the ASN.1 syntax for defining a certTemplate.

[Editor’s Note: The following text provides thoughts about the
design options for this feature.]

Note that we do not necessarily want to repeat the nonce in the
certTemplate field of the CSR. It would be fine to have the nonce
only included in the evidence, as it is done with the PSA Attestation
Token. If the nonce is included in the certTemplate of the CSR
then it should be in the extensions field but there nonce should not
be included in the issued certificate since it offers no value there.
It is, in any case, up to the CA to decide what fields to include
and what not. Hence, this does not appear to be an issue.

It may be useful to augment the CertReqTemplate request with
Information about the type of attestation technology/technologies
Available on the end entity.

#  IANA Considerations

TBD.

#  Security Considerations

This specification adds a nonce to the Certificate Request Template
for use with attestation information in a CSR.

The security considerations of a nonce used for attestation is
Discussed in the RATS architecture specification {{RFC9334}}.

#  Acknowledgments

Add your name here. 

