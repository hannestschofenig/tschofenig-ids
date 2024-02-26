---
title: Nonce-based Freshness for Remote Attestation in Certificate Signing Requests (CSRs) for the Certification Management Protocol (CMP) and for Enrollment over Secure Transport (EST)

abbrev: Nonce Extension for CMP/EST
docname: draft-tschofenig-lamps-nonce-cmp-est-01
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
  RFC5280:
  RFC5785:
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
between client systems and PKI management entities, such as a Registration
Authority (RA) and a Certification Authority (CA).

CMP and EST allow an RA/CA to request additional information it has to
provide in a certification request. When an end entity
places attestation Evidence in a Certificate Signing Request (CSR)
it may need to demonstrate freshness of the provided Evidence.
Attestation technology today often accomplishes this task via the
help of nonces.

This document specifies how nonces are provided by an RA/CA to
the end entity for inclusion in Evidence.

--- middle

#  Introduction

Several protocols have been standardized to automate the management
of certificates, such as certificate issuance, CA certificate provisioning,
certificate renewal and certificate revocation.

The Certificate Management Protocol (CMP) {{I-D.ietf-lamps-rfc4210bis}}
defines protocol messages for X.509v3 certificate creation and
management. CMP provides interactions between end entities and
PKI components, such as a Registration Authority (RA) and a
Certification Authority (CA).

Enrollment over Secure Transport (EST) {{RFC7030}} is another
certificate management protocol, which provides a sub-set
of the features offered by CMP.

An end entity requesting a certificate from a Certification Authority (CA)
may wish to offer believable claims about the protections afforded
to the corresponding private key, such as whether the private key
resides on a hardware security module or the protection capabilities
provided by the hardware, and claims about the platform itself. 

To convey these claims in Evidence, as part of remote attestation,
the remote attestation extension {{I-D.ietf-lamps-csr-attestation}} has
been defined. It describes how to encode Evidence produced by an Attester
for inclusion in Certificate Signing Requests (CSRs), and any
certificates necessary for validating it.

A Verifier or Relying Party might need to learn the point in time
an Evidence has been produced.  This is essential in deciding whether
the included Claims can be considered fresh, meaning they still reflect
the latest state of the Attester.

Attestation technology available today, such as {{TPM20}} and
{{I-D.tschofenig-rats-psa-token}}, often accomplish freshness with
the help of nonces. More details about ensuring freshness of Evidence
can be found in Section 10 of {{RFC9334}}.

Since an end entity needs to obtain a nonce from the Verifier via the
Relying Party, this leads to an additional roundtrip. The CSR is, however,
a one-shot message. For this reason CMP and EST are used by the end entity
to obtain the nonce from the RA/CA.

CMP and EST conveniently offer a mechanism to request
information from the RA/CA prior to a certification request. 

Once the nonce
is obtained the end entity can issue an API call to the Attester
to request Evidence and passes the nonce as an input parameter
into the API call. The returned Evidence is then embedded into
a CSR and returned to the RA/CA in a certification request message.

{{fig-arch}} shows this interaction graphically. The nonce is obtained
in step (1) using the extension to CMP/EST defined in this document.
The CSR extension of {{I-D.ietf-lamps-csr-attestation}} is used to
convey Evidence to the RA/CA in step (2). The Verifier processes the
received information and returns an Attestation Result to the Relying
Party in step (3).

~~~ aasvg
                              .---------------.
                              |               |
                              |   Verifier    |
                              |               |
                              '---------------'
                                   |    ^  |    (3)
                                   |    |  | Attestation
                                   |    |  |   Result
                    (1)            |    |  v
 .------------.   Nonce in    .----|----|-----.
 |            |   CMP or EST  |    |    |     |
 |  End       |<-------------------+    |     |
 |  Entity    |               |         |     |
 |    ^       |-------------->|---------'     |
 |    |       |   Evidence    | Relying       |
 |    v       |   in CSR      | Party (RA/CA) |
 |  Attester  |     (2)       |               |
 |            |               |               |
 '------------'               '---------------'
~~~
{: #fig-arch title="Architecture with Background Check Model."}

The functionality of this document is described in two
sections, namely: 

- {{CMP}} describes how to convey the nonce CMP, and
- {{EST}} offers the equivalent functionality for EST.
- 
# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The terms Attester, Relying Party, Verifier and Evidence are defined
in {{RFC9334}}. The terms end entity, certification authority (CA),
and registration authority (RA) are defined in {{RFC5280}}.

We use the terms Certificate Signing Request (CSR) and certification
request interchangeably.

# Conveying a Nonce in CMP {#CMP}

Section 5.3.19.16 of {{I-D.ietf-lamps-rfc4210bis}} defines the
general request message (genm) and general response (genp). 
The AttestationNonceRequest payload of the genm message, which is
send by the end entity to request a nonce, contains optional
details on the length of nonce the attester requires.  The
AttestationNonceResponse payload of the genp message, which is
sent by the CA/RA in response to a request message by the end
entity, contains the nonce.

~~~
 GenMsg:    {id-it TBD1}, AttestationNonceRequestValue
 GenRep:    {id-it TBD2}, AttestationNonceResponseValue | < absent >

 id-it-AttestationNonceRequest OBJECT IDENTIFIER ::= { id-it TBD1 }
 AttestationNonceRequestValue ::= SEQUENCE SIZE (1..MAX) OF
                                     AttestationNonceRequestContent

 AttestationNonceRequestContent ::= SEQUENCE {
    len ::= INTEGER OPTIONAL,
    -- indicates the required length of the requested nonce
    hint ::= EvidenceHint OPTIONAL
    -- indicates the verifier the needs to provide the nonce
 }

 id-it-AttestationNonceResponse OBJECT IDENTIFIER ::= { id-it TBD2 }
 AttestationNonceResponseValue ::= SEQUENCE SIZE (1..MAX) OF
                                      AttestationNonceResponseContent

 AttestationNonceResponseContent ::= SEQUENCE {
    nonce ::= OCTET STRING
    -- contains the nonce of length len
    -- provided by the verifier indicated with hint
 }
~~~

The use of the general request/response message
exchange leads to an extra roundtrip to convey the nonce from the CA/
RA to the end entity (and ultimately to the Attester inside the end
entity).

The end entity MUST construct a AttestationNonceRequest request message to
trigger the RA/CA to transmit a nonce in the response.

When the RA/CA receive the AttestationNonceRequest content 
information is used to determine that the end entity supports this
specification as well as {{I-D.ietf-lamps-csr-attestation}}.

[Open Issue: Should request message indicate the remote attestation
capability of the end entity rather than relying on "policy
information"?  This may also allow to inform the CA/RA about the type
of attestation technology/technologies available to the end entity.]

 If the end entity supports remote attestation and the policy requires
 Evidence in a CSR to be provided, the RA/CA issues a AttestationNonceResponse
 response containing a nonce.

{{fig-cmp-msg}} showns the interaction graphically.

~~~
End Entity                                          RA/CA
==========                                      =============

              -->>-- AttestationNonceRequest -->>--
                                                Verify request
                                                Generate nonce*
                                                Create response
              --<<-- AttestationNonceResponse --<<--
                      (nonce)

Generate key pair
Generate Evidence*
Generate certification request message
              -->>-- certification request -->>--
                    (+Evidence including nonce)
                                               Verify request
                                               Verify Evidence*
                                               Check for replay*
                                               Issue certificate
                                               Create response
              --<<-- certification response --<<--
Handle response
Store certificate

*: These steps require interactions with the Attester
(on the EE side) and with the Verifier (on the RA/CA side).
~~~
{: #fig-cmp-msg title="CMP Exchange with Nonce and Evidence."}

# Conveying a Nonce in EST {#EST}

The EST client can request an attestation nonce for its Attester.
This function is generally performed after requesting CA certificates
and before other EST functions.

The EST server MUST support the use of the path-prefix of "/.well-
known/" as defined in {{RFC5785}} and the registered name of "est".
Thus, a valid EST server URI path begins with
"https://www.example.com/.well-known/est".  Each EST operation is
indicated by a path-suffix that indicates the intended operation:

The following operation is defined by this specificaion:

~~~
 +------------------------+-----------------+-------------------+
 | Operation              |Operation path   | Details           |
 +========================+=================+===================+
 | Retrieval of a nonce   | /nonce          | This section      |
 +------------------------+-----------------+-------------------+
~~~

The operation path is appended to the path-prefix to form
the URI used with HTTP GET to perform the desired EST
operation.  An example valid URI absolute path for the "/nonce"
operation is "/.well-known/est/nonce".  To retrieve a nonce,
the EST client would use the following HTTP request-line:

~~~
GET /.well-known/est/nonce HTTP/1.1
~~~

The EST server MAY request HTTP-based client authentication, as
explained in Section 3.2.3 of {{RFC7230}}.

If the request is successful, the EST server response MUST contain
a HTTP 200 response code with a content-type of "application/json"
and a JSON object  {{RFC7159}} with the member nonce. The expiry
member is optional and indicates the time the nonce is considered
valid. After the expiry time is expired, the session is likely
garbage collected.

Below is a non-normative example of the response given by the EST server:

~~~
HTTP/1.1 200 OK
Content-Type: application/json

{
    "nonce": "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=",
    "expiry": "2031-10-12T07:20:50.52Z"
}
~~~

[Open Issue: Should we also register a content type for use with
EST over CoAP where the nonce and the expiry field is encoded in
a CBOR structure?]

# Nonce Processing Guidelines

When the RA/CA is requested or configured to transmit a nonce to an
end entity then it interacts with the Verifier.
The Verifier is, according to the IETF RATS architecture {{RFC9334}}, "a role
performed by an entity that appraises the validity of Evidence about
an Attester and produces Attestation Results to be used by a Relying
Party." Since the Verifier validates Evidence it is also the source
of the nonce to check for replay.

The nonce value MUST contain a random byte sequence whereby the length
depends on the used remote attestation technology.
Since the nonce is relayed with the RA/CA, it MUST be copied to
the respective structure, as described in {{EST}} and {{CMP}}, for
transmission to the Attester.

For example, the PSA attestation token {{I-D.tschofenig-rats-psa-token}}
supports nonces of length 32, 48 and 64 bytes. Other attestation
technologies use nonces of similar length. The assumption in this
specification is that the RA/CA have out-of-band knowledge about the
required nonce length required for the attestation technology used by
the end entity. The nonces of incorrect length will cause the remote
attestation protocol to fail.

When the end entity receives the nonce it MUST use it, if remote
attestation is available and supports nonces. It is better for an
RA/CA to be aggressive in sending a nonce, at least where there is a
reasonable chance the client supports remote attestation and the
client should be allowed to ignore the nonce if it either does not
support it or cannot use it for policy reasons.

While the semantics of the attestation API and the software/hardware
architecture is out-of-scope of this specification, the API will return
Evidence from the Attester in a format specific to the attestation technology
utilized. The encoding of the returned evidence varies but will be placed
inside the CSR, as specified in {{I-D.ietf-lamps-csr-attestation}}. The
software creating the CSR will not have to interpret the Evidence format
- it is treated as an opaque blob. It is important to note that the
nonce is carried in the Evidence, either implicitly or explicitly, and
it MUST NOT be conveyed in CSR structures outside the Evidence payload.

The processing of the CSR containing Evidence is described in
{{I-D.ietf-lamps-csr-attestation}}. Note that the issued certificates
does not contain the nonce, as explained in
{{I-D.ietf-lamps-csr-attestation}}.

#  IANA Considerations

[Editor's Note: The ASN.1 module OID (TBD2) and the new private
extension (TBD1) must be registered.]

#  Security Considerations

This specification defines how to obtain a nonce via CMP and EST. This
specification assumes that the nonce does not require confidentiality protection
without impacting the security property of the remote attestation protocol.
{{RFC9334}} defines the IETF remote attestation architecture discusses
nonce-based freshness in great detail.

For the use of Evidence in the CSR the security considerations of
{{I-D.ietf-lamps-csr-attestation}} are relevant to this document.

# ASN.1 Definitions {#asn.1}

TBD:

--- back

# Acknowledgments

We would like to thank Russ Housley, Thomas Fossati, Ionut Mihalcea and Carl Wallace for their review comments.
