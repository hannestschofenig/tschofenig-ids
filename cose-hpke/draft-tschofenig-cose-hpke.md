---
title: Use of Hybrid Public-Key Encryption (HPKE) with CBOR Object Signing and Encryption (COSE)
abbrev: COSE HPKE
docname: draft-tschofenig-cose-hpke-00
category: std

ipr: pre5378Trust200902
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
  toc_levels: 4

author:
 -
       ins: H. Tschofenig
       name: Hannes Tschofenig
       organization: Arm Limited
       email: hannes.tschofenig@arm.com

 -
       ins: R. Housley
       name: Russ Housley
       organization: Vigil Security, LLC
       abbrev: Vigil Security
       email: housley@vigilsec.com

 -
      ins: B. Moran
      name: Brendan Moran
      organization: Arm Limited
      email: Brendan.Moran@arm.com


normative:
  RFC2119:
  RFC8174:
  I-D.irtf-cfrg-hpke:
  RFC8152:
  
informative:
  RFC8937:
  RFC4949: 
  RFC2630:
  
--- abstract

This specification defines hybrid public-key encryption (HPKE) for use with 
CBOR Object Signing and Encryption (COSE). 

--- middle

#  Introduction

Hybrid public-key encryption (HPKE) {{I-D.irtf-cfrg-hpke}} is a scheme that 
provides public key encryption of arbitrary-sized plaintexts given a 
recipient's public key. HPKE utilizes a non-interactive ephemeral-static 
Diffie-Hellman exchange to establish a shared secret, which is then used to 
encrypt plaintext.

The HPKE specification defines several features for use with public key encryption 
and a subset of those features is applied to COSE {{RFC8152}}.

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP&nbsp;14 {{RFC2119}} {{RFC8174}}
when, and only when, they appear in all capitals, as shown here.

This specification uses the following abbreviations and terms:

- Key-encryption key (KEK), a term defined in RFC 4949 {{RFC4949}}. 
- Content-encryption key (CEK), a term defined in RFC 2630 {{RFC2630}}.
- Hybrid Public Key Encryption (HPKE) is defined in {{I-D.irtf-cfrg-hpke}}.
- pkR is the public key of the recipient, as defined in {{I-D.irtf-cfrg-hpke}}.
- skR is the private key of the recipient, as defined in {{I-D.irtf-cfrg-hpke}}.

# HPKE for COSE

## Overview

HPKE, when used with COSE, follows a three layer structure: 

- Layer 0 (corresponding to the COSE_Encrypt structure) contains content encrypted 
with the CEK. This ciphertext may be detached. If not detached, then it is included.

- Layer 1 (see COSE_recipient_outer structure) includes the encrypted CEK.

- Layer 2 (in the COSE_recipient_inner structure) contains parameters needed for 
HPKE to generate the layer 1 key and to encrypt it.

The CDDL for the COSE_Encrypt structure, as used with HPKE,
is shown in {{cddl-hpke}}.

~~~
COSE_Encrypt_Tagged = #6.96(COSE_Encrypt)
 
SUIT_Encryption_Info = COSE_Encrypt_Tagged

; Layer 0
COSE_Encrypt = [
  Headers,
  ciphertext : bstr / nil,
  recipients : [+COSE_recipient_outer]
]

; Layer 1   
COSE_recipient_outer = [
  protected   : bstr .size 0,
  unprotected : header_map, ; must contain alg
  encCEK      : bstr, ; CEK encrypted with HPKE-derived shared secret
  recipients  : [ + COSE_recipient_inner ]  
]

; Layer 2
COSE_recipient_inner = [
  protected   : bstr .cbor header_map, ; must contain HPKE alg
  unprotected : header_map, ; must contain kid and ephemeral public key
  empty       : null,
  empty       : null
]

header_map = {
  Generic_Headers,
  * label =values,
}
~~~
{: #cddl-hpke title="CDDL for HPKE-based COSE_Encrypt Structure"}

The COSE_recipient_outer structure shown in {{cddl-hpke}} includes the 
encrypted CEK (in the encCEK structure) and the COSE_recipient_inner structure, 
also shown in {{cddl-hpke}}, contains the ephemeral public key 
(in the unprotected structure).

## HPKE Encryption with Seal

The SealBase(pkR, info, aad, pt) function is used to encrypt a plaintext pt to 
a recipient's public key (pkR). For use in this specification, the plaintext 
"pt" passed into the SealBase is the CEK. The CEK is a random byte sequence of 
length appropriate for the encryption algorithm selected in layer 0. For example, 
AES-128-GCM requires a 16 byte key and the CEK would therefore be 16 bytes long. 

The "info" parameter that can be used to influence the generation of keys and the 
"aad" parameter that provides Additional Authenticated Data to the AEAD algorithm 
in use. If successful, SealBase() will output a ciphertext "ct" and an encapsulated 
key "enc". 

The content of the info parameter is based on the 'COSE_KDF_Context' structure, 
which is detailed in {{cddl-cose-kdf}}.

## HPKE Decryption with Open

The recipient will use the OpenBase(enc, skR, info, aad, ct) function with the enc and 
ct parameters obtained from the sender. The "aad" and the "info" parameters are obtained 
via the context of the usage. 

The OpenBase function will, if successful, decrypt "ct". When decrypted, the result 
will be the CEK. The CK is the symmetric key used to decrypt the ciphertext in the 
COSE_Encrypt

## Info Structure

This specification re-uses the context information structure defined in 
{{RFC8152}} for use with the HPKE algorithm inside the info structure, 
which is repeated in {{cddl-cose-kdf }} for easier readability. 

~~~
   PartyInfo = (
       identity : bstr / nil,
       nonce : bstr / int / nil,
       other : bstr / nil
   )

   COSE_KDF_Context = [
       AlgorithmID : int / tstr,
       PartyUInfo : [ PartyInfo ],
       PartyVInfo : [ PartyInfo ],
       SuppPubInfo : [
           keyDataLength : uint,
           protected : empty_or_serialized_map,
           ? other : bstr
       ],
       ? SuppPrivInfo : bstr
   ]
~~~
{: #cddl-cose-kdf title="COSE_KDF_Context Data Structure for info parameter"}

Since this specification may be used in a number of different 
deployment environments some flexibility is provided regarding 
how the fields in the COSE_KDF_Context data structure. 

For better interopability, the following recommended settings 
are provided:

- PartyUInfo.identity corresponds to the kid found in the 
COSE_Sign_Tagged or COSE_Sign1_Tagged structure (when a digital 
signature is used). When utilizing a MAC, then the kid is found in 
the COSE_Mac_Tagged or COSE_Mac0_Tagged structure.

- PartyVInfo.identity corresponds to the kid used for the respective 
recipient from the inner-most recipients array.

- The value in the AlgorithmID field corresponds to the alg parameter 
in the protected structure in the inner-most recipients array. 

- keyDataLength is set to the number of bits of the desired output value.

- protected refers to the protected structure of the inner-most array. 

# Example

An example of the COSE_Encrypt structure using the HPKE scheme is 
shown in {{hpke-example}}. It uses the following algorithm 
combination: 

- AES-GCM-128 for encryption of detached ciphertext. 
- AES-GCM-128 for encryption of the CEK.
- Key Encapsulation Mechanism (KEM): NIST P-256
- Key Derivation Function (KDF): HKDF-SHA256
  
~~~
96( 
    [
        // protected field with alg=AES-GCM-128
        h'A10101',   
        {    // unprotected field with iv
             5: h'26682306D4FB28CA01B43B80'
        }, 
        // null because of detached ciphertext
        null,  
        [  // COSE_recipient_outer
            h'',          // empty protected field
            {             // unprotected field with ... 
                 1: 1     //     alg=A128GCM
            },
            // Encrypted CEK
            h'FA55A50CF110908DA6443149F2C2062011A7D8333A72721A',
            / recipients / [  // COSE_recipient_inner
             [
               / protected / h'a1013818' / {
                   \ alg \ 1:TBD1 \ HPKE/P-256+HKDF-256 \
                 } / ,
               / unprotected / {
                 // HPKE encapsulated key
                 / ephemeral / -1:{
                   / kty / 1:2,
                   / crv / -1:1,
                   / x / -2:h'98f50a4ff6c05861c8...90bbf91d6280',
                   / y / -3:true
                 },
                 // kid for recipient static ECDH public key
                 / kid / 4:'meriadoc.brandybuck@buckland.example'
               },
               // empty ciphertext
               / ciphertext / h''
             ]
            ]
        ]
     ]
)
~~~
{: #hpke-example title="COSE_Encrypt Example for HPKE"}

# Security Considerations {#sec-cons}

This specification is based on HPKE and the security considerations of HPKE 
{{I-D.irtf-cfrg-hpke}} are therefore applicable also to this specification.

HPKE assumes that the sender is in possession of the public key of the recipient. 
A system using HPKE COSE has to assume the same assumptions and public key distribution
mechanism is assumed to exist. 

Since the CEK is randomly generated it must be ensured that the guidelines for 
random number generations are followed, see {{RFC8937}}.

#  IANA Considerations

This document requests IANA to create new entries in the COSE Algorithms
registry established with {{RFC8152}}.

~~~
+-------------+-------+---------+------------+--------+---------------+  
| Name        | Value | KDF     | Ephemeral- | Key    | Description   |
|             |       |         | Static     | Wrap   |               |
+-------------+-------+---------+------------+--------+---------------+
| HPKE/P-256+ | TBD1  | HKDF -  | yes        | none   | HPKE with     |
| HKDF-256    |       | SHA-256 |            |        | ECDH-ES       |
|             |       |         |            |        | (P-256) +     |
|             |       |         |            |        | HKDF-256      |
+-------------+-------+---------+------------+--------+---------------+
| HPKE/P-384+ | TBD2  | HKDF -  | yes        | none   | HPKE with     |
| HKDF-SHA384 |       | SHA-384 |            |        | ECDH-ES       |
|             |       |         |            |        | (P-384) +     |
|             |       |         |            |        | HKDF-384      |
+-------------+-------+---------+------------+--------+---------------+
| HPKE/P-521+ | TBD3  | HKDF -  | yes        | none   | HPKE with     |
| HKDF-SHA521 |       | SHA-521 |            |        | ECDH-ES       |
|             |       |         |            |        | (P-521) +     |
|             |       |         |            |        | HKDF-521      |
+-------------+-------+---------+------------+--------+---------------+
| HPKE        | TBD4  | HKDF -  | yes        | none   | HPKE with     |
| X25519 +    |       | SHA-256 |            |        | ECDH-ES       |
| HKDF-SHA256 |       |         |            |        | (X25519) +    |
|             |       |         |            |        | HKDF-256      |
+-------------+-------+---------+------------+--------+---------------+
| HPKE        | TBD4  | HKDF -  | yes        | none   | HPKE with     |
| X448 +      |       | SHA-512 |            |        | ECDH-ES       |
| HKDF-SHA512 |       |         |            |        | (X448) +      |
|             |       |         |            |        | HKDF-512      |
+-------------+-------+---------+------------+--------+---------------+
~~~ 

--- back

# Acknowledgements

TBD: Add your name here. 