---
title: CBOR Object Signing and Encryption (COSE) Key Thumbprint
abbrev: COSE Key Thumbprint
docname: draft-ietf-cose-key-thumbprint-06
category: std

ipr: trust200902
area: Security
workgroup: COSE
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
    ins: K. Isobe
    name: Kohei Isobe
    email: isobekohei@gmail.com
    org: SECOM CO., LTD.

 -
    ins: H. Tschofenig
    name: Hannes Tschofenig
    abbrev: H-BRS
    organization: University of Applied Sciences Bonn-Rhein-Sieg
    country: Germany
    email: hannes.tschofenig@gmx.net

 -
    ins: O. Steele
    name: Orie Steele
    organization: Transmute
    email: orie@transmute.industries
    country: United States

normative:
  RFC2119:
  RFC8949:
  RFC8174:
  RFC9052:
  RFC9053:
  RFC8747:
  RFC8392:
  RFC7515:
  RFC4648:

informative:
  RFC7638:
  RFC6234:
  RFC5280:
  RFC9360:
  RFC9278:
  IANA.Hash.Algorithms:
     title: "Named Information Hash Algorithm Registry"
     target: https://www.iana.org/assignments/named-information
     date: false

--- abstract

This specification defines a method for computing a hash value over a CBOR
Object Signing and Encryption (COSE) Key. It specifies which fields within
the COSE Key structure are included in the cryptographic hash computation,
the process for creating a canonical representation of these fields, and how
to hash the resulting byte sequence. The resulting hash value, referred to
as a "thumbprint," can be used to identify or select the corresponding key.

--- middle

# Introduction

This specification defines a method for applying a cryptographic hash function
to a CBOR Object Signing and Encryption (COSE) Key structure {{RFC9052}}. The
resulting hash value is called thumbprint. To accomplish this task the document
defines which fields in a COSE Key structure are used in the hash computation, the method of creating
a canonical form for those fields, and how to hash the byte sequence.  The resulting
hash value can be used for identifying or selecting the key that is the subject of
the thumbprint, for instance, by using the COSE Key Thumbprint value as a "kid"
(key ID) value. The use of the thumbprint of the key as a naming scheme is one
of the main use cases of this document. Another use case are key derivation
functions that utilize the thumbprints of the public keys of the endpoints,
as well as other context, to the derived symmetric key.

This specification defines how thumbprints of COSE Keys are created for asymmetric
and symmetric keys, see {{thumbprint}} and {{required}}.
Additionally, a new CBOR Web Token (CWT) confirmation method is added to the
IANA "CWT Confirmation Methods" registry created by {{RFC8747}}. See Section 3.1 of
{{RFC8747}} for details about the use of a confirmation claim in a CWT
with a proof-of-possession key.

# Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all
capitals, as shown here.

# COSE Key Thumbprint {#thumbprint}

The thumbprint of a COSE Key MUST be computed as follows:

1. Construct a COSE_Key structure (see Section 7 of {{RFC9052}}) containing
   only the required parameters representing the key as described in 
   Section 4 of this document.

2. Apply the deterministic encoding described in Section 4.2.1 of {{RFC8949}}
   to the representation constructed in step (1).

3. Hash the bytes produced in step (2) with a cryptographic hash function H.
   For example, SHA-256 {{RFC6234}} may be used as a hash function.

The resulting value is the COSE Key Thumbprint with H of the COSE Key. The
details of this computation are further described in subsequent
sections.

The SHA-256 hash algorithm MUST be supported, other algorithms MAY be supported.

# Required COSE Key Parameters {#required}

Only the required parameters of a key's representation are used when
computing its COSE Key Thumbprint value. This section summarizes the
required parameters.

The "kty" (label: 1) element MUST be present for all key types and the integer
value found in the IANA COSE Key Types registry MUST be used. The tstr data
type is not used with the kty element.

Many COSE Key parameters depend on the chosen key type. The subsection below list
the required parameters for commonly used key types.

## Octet Key Pair (OKP)

The required parameters for elliptic curve public keys that use the OKP key type,
such as X25519, are:

- "kty" (label: 1, data type: int, value: 1)
- "crv" (label: -1, value: int)
- "x" (label: -2, value: bstr)

Details can be found in Section 7.1 of {{RFC9053}}.

## Elliptic Curve Keys with X- and Y-Coordinate Pair {#ecc}

The required parameters for elliptic curve public keys that use the EC2 key type, such
as NIST P-256, are:

- "kty" (label: 1, data type: int, value: 2)
- "crv" (label: -1, data type: int)
- "x" (label: -2, data type: bstr)
- "y" (label: -3, data type: bstr)

Details can be found in Section 7.1 of {{RFC9053}}.

Note: {{RFC9052}} offers both compressed as well as uncompressed point
representations. For interoperability, implementations following this
specification MUST use the uncompressed point representation. Hence,
the y-coordinate is expressed as a bstr. An implementation that uses
the compressed point representation MUST compute the uncompressed
representation for the purpose of the thumbprint calculation.

## RSA Public Keys

The required parameters for an RSA public key are:

- "kty" (label: 1, data type: int, value: 3)
- "n" (label: -1, data type: bstr)
- "e" (label: -2, data type: bstr)

## Symmetric Keys

The required parameters for a symmetric key are:

- "kty" (label: 1, data type: int, value: 4)
- "k" (label: -1, data type: bstr)

## HSS-LMS

The required parameters for HSS-LMS keys are:

- "kty" (label: 1, data type: int, value: 5)
- "pub" (label: -1, data type: bstr)

## Others

As other key type values are defined, the specifications
defining them should be similarly consulted to determine which
parameters, in addition to the "kty" element, are required.

# Miscellaneous Considerations

## Why Not Include Optional COSE Key Parameters?

Optional parameters of COSE Keys are intentionally not included in the
COSE Key Thumbprint computation so that their absence or presence
in the COSE Key does not alter the resulting value.  The COSE Key
Thumbprint value is a digest of the parameters required to represent
the key as a COSE Key -- not of additional data that may also
accompany the key.

Optional parameters are not included so that the COSE Key Thumbprint refers
to a key -- not a key with an associated set of key attributes.
Different application contexts might or might not include different
subsets of optional attributes about the key in the COSE Key structure.
If these were included in the calculation of the COSE Key Thumbprint,
the values would be different for those COSE Keys, even though the keys
are the same. The benefit of including only the required parameters is that the
COSE Key Thumbprint of any COSE Key representing the key remains the same,
regardless of any other attributes that are present.

Different kinds of thumbprints could be defined by other specifications
that might include some or all additional COSE Key parameters, if use
cases arise where such different kinds of thumbprints would be useful.

## Selection of Hash Function

A specific hash function must be chosen by an application to compute
the hash value of the hash input.  For example, SHA-256 {{RFC6234}} might
be used as the hash function by the application.  While SHA-256 is a
good default choice at the time of writing, the hash function of
choice can be expected to change over time as the cryptographic
landscape evolves.

Note that in many cases, only the party that creates a key will need
to know the hash function used.  A typical usage is for the producer
of the key to use the thumbprint value as a "kid" (key ID) value. In
this case, the consumer of the "kid" treats it as an opaque value that
it uses to select the key.

However, in some cases, multiple parties will be reproducing the COSE Key
Thumbprint calculation and comparing the results.  In these cases,
the parties will need to know which hash function was used and use
the same one.

## Thumbprints of Keys Not in COSE Key Format

Keys that are in other formats can be represented as COSE Keys.
Any party in possession of a key that is represented as a COSE Key can
use the COSE Key Thumbprint. 

## Relationship to Digests of X.509 Values

COSE Key Thumbprint values are computed on the COSE Key object required to
represent a key, rather than all parameters of a COSE Key that the key is
represented in.  Thus, they are more analogous to applications that
use digests of X.509 Subject Public Key Info (SPKI) values, which are
defined in Section 4.1.2.7 of {{RFC5280}}, than to applications that
use digests of complete certificate values, as the "x5t" (X.509
certificate SHA-1 thumbprint) {{RFC9360}} value defined for X.509
certificate objects does.  While logically equivalent to a digest of
the SPKI representation of the key, a COSE Key Thumbprint is computed over
the CBOR representation of that key, rather than over an ASN.1
representation of it.

## Confirmation Method

{{RFC8747}} introduced confirmation methods for use with CBOR
Web Tokens (CWTs) with the addition of the "cnf" claim. CWTs have
been defined in {{RFC8392}}. This specification adds a new
confirmation method based on COSE Key Thumbprints.

The proof-of-possession key is identified using the "ckt" claim,
the COSE Key Thumbprint claim. This claim contains the value of
the COSE Key Thumbprint encoded as a binary string. Instead of
communicating the actual COSE Key only the thumbprint is conveyed.
This approach assumes that the recipient is able to obtain the
identified COSE Key using the thumbprint contained in the "ckt"
claim. In this approach, the issuer of a CWT declares that the
presenter possesses a particular key and that the recipient
can cryptographically confirm the presenter's proof of possession
of the key by including a "ckt" claim in the CWT.

The following example demonstrates the use of the "ckt" claim
in a CWT as part of the confirmation method (with line-breaks inserted
for editorial reasons):

~~~
   {
    /iss/ 1 : "coaps://as.example.com",
    /aud/ 3 : "coaps://resource.example.org",
    /exp/ 4 : 1361398824,
    /cnf/ 8 : {
      /ckt/ [[TBD1]] : h'496bd8afadf307e5b08c64b0421bf9dc
                  01528a344a43bda88fadd1669da253ec'
     }
   }
~~~

{{IANA}} registers the "ckt" claim and the confirmation method.
The "ckt" claim is expected to be used in the "cnf" claim.

## COSE Key Thumbprint URIs

This specification defines Uniform Resource Identifiers (URIs)
to represent a COSE Key Thumbprint value. The design follows
the work of the JSON Web Key (JWK) Thumbprint URIs, specified
in {{RFC9278}}. This enables COSE Key Thumbprints to be used,
for example, as key identifiers in contexts requiring URIs.
This specification defines a URI prefix indicating that the
portion of the URI following the prefix is a COSE Key Thumbprint.

The following URI prefix is defined to indicate that the portion
of the URI following the prefix is a COSE Key Thumbprint:

~~~
  urn:ietf:params:oauth:ckt
~~~

To make the hash algorithm being used explicit in a URI, the prefix
is followed by a hash algorithm identifier and a COSE Key Thumbprint
value, each separated by a colon character to form a URI representing
a COSE Key Thumbprint.

Hash algorithm identifiers used in COSE Key Thumbprint URIs MUST be values
from the "Hash Name String" column in the IANA "Named Information
Hash Algorithm Registry" {{IANA.Hash.Algorithms}}. COSE Key Thumbprint URIs
with hash algorithm identifiers not found in this registry are not
considered valid and applications MUST detect and handle this
error, should it occur.

Since the URN is encoded as a string, the output of the COSE Key
Thumbprint computation described in {{thumbprint}} MUST be base64url
encoded without padding.

{{RFC7515}} specifies Base64url encoding as follows:

"Base64 encoding using the URL- and filename-safe character set
defined in Section 5 of RFC 4648 {{RFC4648}}, with all trailing '='
characters omitted and without the inclusion of any line breaks,
whitespace, or other additional characters.  Note that the base64url
encoding of the empty octet sequence is the empty string.
(See Appendix C of {{RFC7515}} for notes on implementing base64url
encoding without padding.)"

The base64url encoding of the thumbprint shown in {{example}} is
shown below (with a line-break added for readability purposes).

~~~
SWvYr63zB-WwjGSwQhv53AFSijRKQ72oj63RZp2iU-w
~~~

The full example of a COSE Key Thumbprint URI is shown below, again
with a line-break added.

~~~
urn:ietf:params:oauth:ckt:sha-256:
SWvYr63zB-WwjGSwQhv53AFSijRKQ72oj63RZp2iU-w
~~~

# Example {#example}

This section demonstrates the COSE Key Thumbprint computation for the
following example COSE Key containing an ECC public key.

For better readability, the example is first presented in CBOR diagnostic format (with
the long line broken for display purposes only).

~~~
  {
    / kty set to EC2 = Elliptic Curve Keys /
    1:2,
    / crv set to P-256 /
    -1:1,
    / public key: x-coordinate /
    -2:h'65eda5a12577c2bae829437fe338701a10aaa375e1bb5b5de108de439c0
8551d',
    / public key: y-coordinate /
    -3:h'1e52ed75701163f7f9e40ddf9f341b3dc9ba860af7e0ca7ca7e9eecd008
4d19c',
    / kid is bstr, not used in COSE Key Thumbprint /
    2:h'1decade2facade3'
  }
~~~

The example above corresponds to the following CBOR encoding
(with link breaks added for display purposes only):

~~~
A50102200121582065EDA5A12577C2BAE829437FE338701A10AAA375E1BB5B5DE108D
E439C08551D2258201E52ED75701163F7F9E40DDF9F341B3DC9BA860AF7E0CA7CA7E9
EECD0084D19C0258246D65726961646F632E6272616E64796275636B406275636B6C6
16E642E6578616D706C65
~~~

Not all of the parameters from the example above are used in the COSE Key
Thumbprint computation since the required parameters of an elliptic curve
public key are (as listed in {{ecc}}) "kty", "crv", "x", and "y".

The resulting COSE Key structure, in CBOR diagnostic format with
line-breaks added for better readability, with the minimum parameters
in the correct order are.

~~~
{
   1:2,
  -1:1,
  -2:h'65eda5a12577c2bae829437fe338701a
       10aaa375e1bb5b5de108de439c08551d',
  -3:h'1e52ed75701163f7f9e40ddf9f341b3d
       c9ba860af7e0ca7ca7e9eecd0084d19c'
}
~~~

In CBOR encoding the result is (with line-breaks added for display
purposes only):

~~~
A40102200121582065EDA5A12577C2BAE829437FE338701A10AAA375E1BB5B5DE
108DE439C08551D2258201E52ED75701163F7F9E40DDF9F341B3DC9BA860AF7E0
CA7CA7E9EECD0084D19C
~~~

Using SHA-256, the resulting thumbprint is:

~~~
496bd8afadf307e5b08c64b0421bf9dc01528a344a43bda88fadd1669da253ec
~~~

# Security Considerations

A COSE Key Thumbprint will only uniquely identify a particular key if a
single unambiguous COSE Key representation for that key is defined and
used when computing the COSE Key Thumbprint.

If two asymmetric keys are used by different parties with different
key identifiers then the COSE Key Thumbprints will still be equal since
the key identifier itself is not included in the thumbprint calculation
(similarly to other optional parameters in the COSE_Key structure).
When the inclusion of certain optional parameters in the thumbprint
calcuation is important for a given application, this specification
is not the appropriate choice.

While thumbprint values are useful for identifying legitimate keys,
comparing thumbprint values is not a reliable means of excluding the
use of particular keys (or transformations thereof). The reason is
that an attacker may supply a key that is a transformation of a key
in order to have it appear to be a different key.  For instance, if
a legitimate RSA key uses a modulus value N and an attacker supplies
a key with modulus 3*N, the modified key would still work about 1/3
of the time, but would appear to be a different key.  

Producing thumbprints of symmetric keys needs to be done with care. Developers
MUST ensure that the symmetric key has sufficient entropy to prevent
attackers to precompute tables of symmetric keys with their corresponding
hash values. This can be prevented if the symmetric key is a randomly
selected key of at least 128 bit length. Thumbprints MUST NOT be used 
with passwords or other low-entropy secrets. If a
developer is unable to determine whether all symmetric keys used in an
application have sufficient entropy, then thumbprints of symmetric keys
MUST NOT be used. In general, using thumbprints of symmetric keys should
only be used in special applications. In most other deployment scenarios
it is more appropriate to utilize a different naming scheme for key
identifiers.

# IANA Considerations {#IANA}

IANA is requested to add the following entry to the IANA "CWT Confirmation
Methods" registry established by {{RFC8747}}:

- Confirmation Method Name: ckt
- Confirmation Method Description: COSE Key SHA-256 Thumbprint
- JWT Confirmation Method Name: jkt
- Confirmation Key: [[TBD1]]
- Confirmation Value Type(s): binary string
- Change Controller: IETF
- Specification Document(s): [[This document]]

Furthermore, IANA is requested to add a value to the IANA "OAuth URI" registry
established with {{!RFC6755}}:

- URN:  urn:ietf:params:oauth:ckt
- Common Name:  COSE Key Thumbprint URI
- Change controller:  IETF
- Specification Document:  [[This document]]

# Acknowledgements

We would like to thank the authors of {{RFC7638}} for their work on the
JSON Web Key (JWK) Thumbprint specification. This document applies JWK
Thumbprints to COSE Key structures.

Additionally, we would like to thank Carsten Bormann, Ilari Liusvaara,
Laurence Lundblade, Daisuke Ajitomi, Michael Richardson, Michael B. Jones,
Mallory Knodel, Joel Jaeggli, and Brendan Moran for their feedback.
