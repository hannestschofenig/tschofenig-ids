---
title: COSE Key Thumbprint
abbrev: 
docname: draft-isobe-cose-key-thumbprint-02
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
      email: hannes.tschofenig@gmx.net

normative:
  RFC2119:
  RFC8949:
  RFC8174:
  RFC9052:
  RFC9053:

informative:
  RFC7638:
  RFC6234:
  RFC5280:
  RFC9360:

--- abstract

   This specification defines a method for computing a hash value over a
   COSE Key. It defines which fields in a COSE Key structure are used in the
   hash computation, the method of creating a canonical form of the fields,
   and how to hash the byte sequence. The resulting hash value can be used
   for identifying or selecting a key that is the subject of the thumbprint.

--- middle

# Introduction

   This specification defines a method for computing a hash value (a.k.a. digest)
   over a COSE Key structure {{RFC9052}}.  It defines which fields in a COSE Key
   structure are used in the hash computation, the method of creating a canonical
   form for those fields, and how to hash the byte sequence.  The resulting hash
   value can be used for identifying or selecting the key that is the subject of
   the thumbprint, for instance, by using the COSE Key Thumbprint value as a "kid"
   (key ID) value.

   This specification only defines how thumbprints of public keys are created, not
   private keys or symmetric keys.

# Terminology

   The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
   "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
   "OPTIONAL" in this document are to be interpreted as described in
   BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all
   capitals, as shown here.

# COSE Key Thumbprint

   The thumbprint of a COSE Key MUST be computed as follows:

   1. Construct a COSE_Key structure (see Section 7 of {{RFC9052}}) containing
       only the required elements representing the key. This specification
       describes what those required elements are and what, if necessary, 
       what the unique encoding is.

   2. Apply the deterministic encoding described in Section 4.2.1 of {{RFC8949}}
      to the representation constructed in step (1).

   3.  Hash the bytes produced in step (2) with a cryptographic hash function H.
       For example, SHA-256 {{RFC6234}} may be used as a hash function.

   The resulting value is the COSE Key Thumbprint with H of the COSE Key.  The
   details of this computation are further described in subsequent
   sections.

# Required COSE Key Elements {#required}

   Only the required elements of a key's representation are used when
   computing its COSE Key Thumbprint value. This section summarizes the
   required elements.


   The "kty" (label: 1) element MUST be present for all key types and the integer
   value found in the IANA COSE Key Types registry MUST be used. The tstr data
   type is not used with the kty element. 
   
   Many COSE Key elements depend on the chosen key type. The subsection below list
   the required elements for commonly used key types.

## Octet Key Pair (OKP)

The required elements for elliptic curve public keys that use the OKP key type,
such as X25519, are:

   -  "kty" (label: 1, data type: int, value: 1)
   -  "crv" (label: -1, value: int)
   -  "x" (label: -2, value: bstr)

Details can be found in Section 7.1 of {{RFC9053}}.

## Elliptic Curve Keys w/ x- and y-coordinate pair

The required elements for elliptic curve public keys that use the EC2 key type, such
as NIST P-256, are:

   -  "kty" (label: 1, data type: int, value: 2)
   -  "crv" (label: -1, data type: int)
   -  "x" (label: -2, data type: bstr)
   -  "y" (label: -3, data type: bstr)

Details can be found in Section 7.1 of {{RFC9053}}.

Note: {{RFC9052}} offers both compressed as well as uncompressed point
representations. For interoperability, implementations following this 
specification MUST use the uncompressed point representation. Hence, 
the y-coordinate is expressed as a bstr. An implementation that uses 
the compressed point representation MUST compute the uncompressed 
representation for the purpose of the thumbprint calculation.

## RSA Public Keys

   The required elements for an RSA public key are:

   -  "kty" (label: 1, data type: int, value: 3)
   -  "n" (label: -1, data type: bstr)
   -  "e" (label: -2, data type: bstr)

## HSS-LMS

The required elements for HSS-LMS keys are:

   -  "kty" (label: 1, data type: int, value: 5)
   -  "pub" (label: -1, data type: bstr)

## Others

   As other key type values are defined, the specifications
   defining them should be similarly consulted to determine which
   elements, in addition to the "kty" element, are required.

## Why Not Include Optional COSE Key Elements?

   Optional elements of COSE Keys are intentionally not included in the
   COSE Key Thumbprint computation so that their absence or presence
   in the COSE Key does not alter the resulting value.  The COSE Key
   Thumbprint value is a digest of the elements required to represent
   the key as a COSE Key -- not of additional data that may also 
   accompany the key.

   Optional elements are not included so that the COSE Key Thumbprint refers
   to a key -- not a key with an associated set of key attributes.
   Different application contexts might or might not include different
   subsets of optional attributes about the key in the COSE Key structure.
   If these were included in the calculation of the COSE Key Thumbprint,
   the values would be different for those COSE Keys, even though the keys
   are the same. The benefit of including only the required elements is that the
   COSE Key Thumbprint of any COSE Key representing the key remains the same,
   regardless of any other attributes that are present.

   Different kinds of thumbprints could be defined by other
   specifications that might include some or all additional COSE Key elements,
   if use cases arise where such different kinds of thumbprints would be
   useful.

##  Selection of Hash Function

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

## Relationship to Digests of X.509 Values

   COSE Key Thumbprint values are computed on the COSE Key element required to
   represent a key, rather than all members of a COSE Key that the key is
   represented in.  Thus, they are more analogous to applications that
   use digests of X.509 Subject Public Key Info (SPKI) values, which are
   defined in Section 4.1.2.7 of {{RFC5280}}, than to applications that
   use digests of complete certificate values, as the "x5t" (X.509
   certificate SHA-1 thumbprint) {{RFC9360}} value defined for X.509
   certificate objects does.  While logically equivalent to a digest of
   the SPKI representation of the key, a COSE Key Thumbprint is computed over
   the CBOR representation of that key, rather than over an ASN.1
   representation of it.

# Example

   This section demonstrates the COSE Key Thumbprint computation for the
   following example COSE Key containing an ECC public key.

   For better readability, the example is first presented in JSON (with 
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
    / kid /
    2:'meriadoc.brandybuck@buckland.example'
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

Not all of the elements from the example above are used in the COSE Key
Thumbprint since the required elements of an elliptic curve public key are:

   -  "kty"
   -  "crv"
   -  "x"
   -  "y"

The required order based on Section 4.2.1 of {{RFC8949}} is:

   -  "y" (label: -3, data type: bstr)
   -  "x" (label: -2, data type: bstr)
   -  "crv" (label: -1, data type: int)
   -  "kty" (label: 1, data type: int)

The resulting COSE Key structure, in CBOR diagnostic format with
line-breaks added for better readability, with the minimum elements 
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
   (similarly to other optional elements in the COSE_Key structure). 
   When the inclusion of certain optinal elements in the thumbprint calcuation
   is important for a given application, this specification is not the
   appropriate choice. 

   To promote interoperability among implementations, the SHA-256 hash
   algorithm is mandatory to implement.

   While thumbprint values are valuable for
   identifying legitimate keys, comparing thumbprint values is not a
   reliable means of excluding the use of particular keys
   (or transformations thereof). The reason is that an attacker may
   supply a key that is a transformation of a key in order to have it 
   appear to be a different key.  For instance, if a legitimate RSA key
   uses a modulus value N and an attacker supplies a key with modulus 3*N,
   the modified key would still work about 1/3 of the time, but would appear
   to be a different key.  

# IANA Considerations

There are no actions for IANA.

# Acknowledgements

We would like to thank the authors of {{RFC7638}} for their work on the
JSON Web Key (JWK) Thumbprint specification. This document applies JWK
Thumbprints to COSE Key structures.

Additionally, we would like to thank Carsten Bormann, Orie Steele,
Ilari Liusvaara, Laurence Lundblade, Daisuke Ajitomi, and Michael Richardson
for their feedback.