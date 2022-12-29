---
title: "Automatic Implementation of Secure Silicon (AISS) Attestation Token"
abbrev: "AISS Attestation Token"
docname: draft-tschofenig-rats-aiss-token-01
category: info
submissionType: independent

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
  text-list-symbols: -o*+

author:
 -
    ins: H. Tschofenig
    name: Hannes Tschofenig
    organization: Arm Limited
    email: Hannes.Tschofenig@arm.com
 -
    ins: A. Kankaanpää
    name: Arto Kankaanpää
    organization: Synopsys
    email: arto.kankaanpaa@synopsys.com
 -
    ins: N. Bowler
    name: Nick Bowler
    organization: Synopsys
    email: nick.bowler@synopsys.com
 -
    ins: T. Khandelwal
    name: Tushar Khandelwal
    organization: Arm Limited
    email: Tushar.Khandelwal@arm.com
 -
    ins: D. Sahoo
    name: Durga Prasad Sahoo
    organization: Synopsys
    email: Durga.Sahoo@synopsys.com

normative:
  IANA-CWT:
    author:
      org: IANA
    title: CBOR Web Token (CWT) Claims
    target: https://www.iana.org/assignments/cwt/cwt.xhtml#claims-registry
    date: 2022

informative:
  IANA-MediaTypes:
    author:
      org: IANA
    title: Media Types
    target: http://www.iana.org/assignments/media-types
    date: 2022
  IANA-CoAP-Content-Formats:
    author:
      org: IANA
    title: CoAP Content-Formats
    target: https://www.iana.org/assignments/core-parameters
    date: 2022

--- abstract

This specification defines a profile of the Entity Attestation Token (EAT) for use in
special System-on-Chip (SoC) designs that are generated automatically utilizing a
methodology currently developed in a DARPA funded project.

The term "AISS Token" is used to refer to a token that complies to this profile.
The AISS Token is used as Evidence and processed by a Verifier.

--- middle

# Introduction

The DARPA-funded project Automatic Implementation of Secure Silicon (AISS) is aimed at 
making scalable on-chip security pervasive. The objective is to develop ways to automate
the process of adding security into integrated circuits.

If successful, AISS will allow security to be inexpensively incorporated into chip designs
with minimal effort and expertise, ultimately making scalable on-chip security ubiquitous.
The project seeks to create a novel, automated chip design flow that will allow the security
mechanisms to scale consistently with the goals of the design.

As a minimal component, the generated chip designs must offer attestation capabilities.

This specification describes the minimal claim set offered by an attestation token
conforming to the Entity Attestation Token (EAT) specification. This attestation
token (in form of Evidence) is, on request, provided to a Verifier.

# Conventions and Definitions

{::boilerplate bcp14}

The following term is used in this document:

RoT
: Root of Trust, the minimal set of software, hardware and data that has to be
implicitly trusted in the platform - there is no software or hardware at a
deeper level that can verify that the Root of Trust is authentic and
unmodified.  An example of RoT is an initial bootloader in ROM, which contains
cryptographic functions and credentials, running on a specific hardware
platform.

This specification re-uses terms defined in {{!I-D.ietf-rats-architecture}}.


# Claims
{: #sec-claims }

This section describes the claims to be used in an AISS attestation token.

CDDL {{!RFC8610}} along with text descriptions is used to define each claim
independent of encoding.  The following CDDL type(s) are reused by different
claims:

~~~
{::include cddl/aiss-common-types.cddl}
~~~

## Nonce Claim
{: #sec-nonce-claim}

The Nonce claim is used to carry the challenge provided by the caller to
demonstrate freshness of the generated token.

The EAT {{!I-D.ietf-rats-eat}} `nonce` (claim key 10) is used.  The following
constraints apply to the `nonce-type`:

* The length MUST be either 32, 48, or 64 bytes.
* Only a single nonce value is conveyed. Per {{!I-D.ietf-rats-eat}} the array
notation is not used for encoding the nonce value.


This claim MUST be present in an AISS attestation token.

~~~
{::include cddl/aiss-nonce.cddl}
~~~

## Instance ID Claim
{: #sec-instance-id-claim}

The Instance ID claim represents the unique identifier of the
attestation key.

For the Instance ID claim, the EAT `ueid` (claim key 256) of type 
RAND is used.  The following constraints apply to the `ueid-type`:

* The length MUST be 17 bytes.
* The first byte MUST be 0x01 (RAND) followed by the 16-bytes random
value, which may be created by hashing the key identifier or may be
the key identifier itself.

This claim MUST be present in an AISS attestation token.

~~~
{::include cddl/aiss-instance-id.cddl}
~~~

## Implementation ID Claim
{: #sec-implementation-id}

The Implementation ID claim uniquely identifies the implementation of the
immutable RoT. A Verifier uses this claim to locate the
details of the RoT implementation from a manufacturer. Such details are used
by a Verifier to determine the security properties or
certification status of the RoT implementation.

The value and format of the ID is decided by the manufacturer or a
particular certification scheme. For example, the ID could take the
form of a product serial number, database ID, or other appropriate
identifier.

This claim MUST be present in an AISS attestation token.

Note that this identifies the RoT implementation, not a particular instance.
The Instance ID claim, see {{sec-instance-id-claim}}, uniquely identifies an
instance.

~~~
{::include cddl/aiss-implementation-id.cddl}
~~~

## Security Lifecycle Claim
{: #sec-security-lifecycle }

The Security Lifecycle claim represents the current lifecycle state of the 
RoT. The state is represented by an unsigned integer.

The lifecycle states are illustrated in {{fig-lifecycle-states}}. When the
device is deployed, a Verifier can only trust reports when the lifecycle
state is in "Secured" and "Non-RoT Debug" states. The states "Testing"
and "Provisioning" are utilized during manufacturing. A device is in 
"Decommisioned" state when it is retired.

This claim MUST be present in an AISS attestation token.

~~~
  .-------------.        .-------------.
 +    Testing   |-------> Provisioning |
 '-------------'        '------+------'
                               |   .------------------.
                               |  |                    |
                               v  v                    |
                          .---------.                  |
                .---------+ Secured +-----------.      |
                |         '-+-------'            |     |
                |           |     ^              |     |
                |           v     |              v     |
                |    .------------+------.  .----------+----.
                |    | Non-RoT Debug     |  | Recoverable   |
                v    '---------+---------'  | RoT Debug     |
 .----------------.            |            '------+--------'
 | Decommissioned |<-----------+-------------------'
 '----------------'
~~~
{: #fig-lifecycle-states title="Lifecycle States."}


~~~
{::include cddl/aiss-security-lifecycle.cddl}
~~~

## Boot Count Claim
{: #sec-boot-count }

The "bootcount" claim contains a count of the number times the entity or submod has been booted. Support for this claim requires a persistent storage on the device.

The EAT `boot-count-label` (claim key TBD) of type unsigned integer is used. 

This claim MUST be present in an AISS attestation token.

~~~
{::include cddl/aiss-boot-count.cddl}
~~~

## Watermark Claim
{: #sec-watermark }

Watermarking, the process of marking an asset with a known structure,
is used to detect intellectual property (IP) theft and overuse. Watermarking
in hardware IPs is the mechanism of embedding a unique "code" into IP
without altering the original functionality of the design. The ownership
of the IP can be later verified when the watermark is extracted. 

The Watermark claim contains a code extracted from the watermarking
hardware identified by an identifier. This identifier is formated
as a type 4 UUID {{!RFC4122}}.

This claim MUST be present in an AISS attestation token when the
attestation token request asked for a watermark to be present.

~~~
{::include cddl/aiss-watermark.cddl}
~~~


## Profile Definition Claim
{: #sec-profile-definition-claim}

The Profile Definition claim encodes the unique identifier that corresponds to
the EAT profile described by this document.  This allows a receiver to assign
the intended semantics to the rest of the claims found in the token.

The EAT `profile` (claim key 265) is used.  The following constraints
apply to its type:

* The URI encoding MUST be used.
* The value MUST be `https://www.rfc-editor.org/rfc/rfcTBD`.

This claim MUST be present in an AISS attestation token.

~~~
{::include cddl/aiss-profile.cddl}
~~~


# Token Encoding and Signing
{: #sec-token-encoding-and-signing}

The AISS attestation token is encoded in CBOR {{!RFC8949}} format.  Only
definite-length string, arrays, and maps are allowed.

Cryptographic protection is accomplished by COSE. The signature
structure MUST be COSE_Sign1. Only the use of asymmetric key algorithms is
envisioned.

The CWT CBOR tag (61) is not used.  An application that needs to exchange PSA
attestation tokens can wrap the serialised COSE_Sign1 in a dedicated media
type, as for example defined in defined in {{sec-iana-media-types}} or the CoAP Content-Format defined in
{{sec-iana-coap-content-format}}.

# Freshness Model

The AISS attestation token supports the freshness models for attestation Evidence
based on nonces (Section 10.2 and 10.3 of {{!I-D.ietf-rats-architecture}}) using
the `nonce` claim to convey the nonce supplied by the Verifier. No further
assumption on the specific remote attestation protocol is made.

# Collated CDDL

~~~
{::include cddl/aiss-token.cddl}
{::include cddl/aiss-common-types.cddl}
{::include cddl/aiss-nonce.cddl}
{::include cddl/aiss-instance-id.cddl}
{::include cddl/aiss-implementation-id.cddl}
{::include cddl/aiss-security-lifecycle.cddl}
{::include cddl/aiss-boot-count.cddl}
{::include cddl/aiss-watermark.cddl}
{::include cddl/aiss-profile.cddl}
~~~

# AISS Token Appraisal

To process the token by a Verifier, the primary need is to check correct encoding and signing
as detailed in {{sec-token-encoding-and-signing}}.  In particular, the Instance
ID claim is used (together with the kid in the COSE header, if present)
to assist in locating the public key used to verify the signature covering the token.
The key used for verification is supplied to the Verifier by an authorized
Endorser along with the corresponding Attester's Instance ID.

In addition, the Verifier will typically operate a policy where values of some
of the claims in this profile can be compared to reference values, registered
with the Verifier for a given deployment, in order to confirm that the device
is endorsed by the manufacturer supply chain.  The policy may require that the
relevant claims must have a match to a registered reference value.

The protocol used to convey Endorsements and Reference Values to the Verifier
is not in scope for this document.

# IANA Considerations

## Claim Registration

This specification requests IANA to register the following claims in the "CBOR
Web Token (CWT) Claims" registry {{IANA-CWT}}.

### Security Lifecycle Claim

* Claim Name: aiss-security-lifecycle
* Claim Description: AISS Security Lifecycle
* JWT Claim Name: N/A
* Claim Key: TBD (requested value: 2500)
* Claim Value Type(s): unsigned integer
* Change Controller: [[Authors of this RFC]]
* Specification Document(s): {{sec-security-lifecycle}} of [[this RFC]]

### Implementation ID Claim

* Claim Name: aiss-implementation-id
* Claim Description: AISS Implementation ID
* JWT Claim Name: N/A
* Claim Key: TBD (requested value: 2501)
* Claim Value Type(s): byte string
* Change Controller: [[Authors of this RFC]]
* Specification Document(s): {{sec-implementation-id}} of [[this RFC]]

### Watermark Claim

* Claim Name: aiss-watermark
* Claim Description: AISS Watermark
* JWT Claim Name: N/A
* Claim Key: TBD (requested value: 2502)
* Claim Value Type(s): byte string
* Change Controller: [[Authors of this RFC]]
* Specification Document(s): {{sec-watermark}} of [[this RFC]]


## The AISS Token Profile

This specification defines a profile of an EAT.

The identifier for this profile is "https://www.rfc-editor.org/rfc/rfcTBD".

| Issue | Profile Definition |
| CBOR/JSON | CBOR only |
| CBOR Encoding | Only definite length maps and arrays are allowed |
| CBOR Encoding | Only definite length strings are allowed |
| CBOR Serialization | Only preferred serialization is allowed |
| COSE Protection | Only COSE_Sign1 format is used |
| Algorithms | Receiver MUST accept ES256, ES384 and ES512; sender MUST send one of these |
| Detached EAT Bundle Usage | Detached EAT bundles are not sent with this profile |
| Verification Key Identification | The Instance ID claim MUST be used to identify the verification key. |
| Endorsements | This profile contains no endorsement identifier |
| Nonce | A new single unique nonce MUST be used for every token request |
| Claims | The claims listed in this specification MUST be implemented and understood by the receiver. As per general EAT rules, the receiver MUST NOT error out on claims it does not understand. |


## Media Type Registration
{: #sec-iana-media-types}

IANA is requested to register the "application/aiss-attestation-token" media
type {{!RFC2046}} in the "Media Types" registry {{IANA-MediaTypes}} in the
manner described in RFC 6838 {{!RFC6838}}, which can be used to indicate that
the content is an AISS Attestation Token.

* Type name: application
* Subtype name: aiss-attestation-token
* Required parameters: n/a
* Optional parameters: n/a
* Encoding considerations: binary
* Security considerations: See the Security Considerations section
  of [[this RFC]]
* Interoperability considerations: n/a
* Published specification: [[this RFC]]
* Applications that use this media type: Attesters and Relying Parties sending
  AISS attestation tokens over HTTP(S), CoAP(S) and other transports.
* Fragment identifier considerations: n/a
* Additional information:

  * Magic number(s): n/a
  * File extension(s): n/a
  * Macintosh file type code(s): n/a

* Person & email address to contact for further information:
  Hannes Tschofenig, Hannes.Tschofenig@arm.com
* Intended usage: COMMON
* Restrictions on usage: none
* Author: Hannes Tschofenig, Hannes.Tschofenig@arm.com
* Change controller: IESG
* Provisional registration?  No


## CoAP Content-Formats Registration
{: #sec-iana-coap-content-format}

IANA is requested to register the CoAP Content-Format ID for the
"application/aiss-attestation-token" media type in the "CoAP Content-Formats"
registry {{IANA-CoAP-Content-Formats}}.

### Registry Contents

*  Media Type: application/aiss-attestation-token
*  Encoding: -
*  Id: [[To-be-assigned by IANA]]
*  Reference: [[this RFC]]


--- back

# Example

The following example shows an AISS attestation token for an hypothetical system.
The attesting device is in a lifecycle state {{sec-security-lifecycle}} of
SECURED.

The claims in this example are:

~~~
{::include cddl/example/aiss-token.diag}
~~~

The resulting COSE object is:

~~~
{::include cddl/example/aiss-cose.diag}
~~~


# Acknowledgments
{:numbered="false"}

We would like to thank Rob Aitken, Mike Borza, Liam Dillon, Dale Donchin, John Goodenough, Oleg Raikhman, Henk Birkholz, Ned Smith, and Laurence Lundblade for their feedback.

Work on this document has in part been supported by the DARPA AISS project (grant agreement
HR0011-20-9-0043, see https://www.darpa.mil/program/automatic-implementation-of-secure-silicon).


