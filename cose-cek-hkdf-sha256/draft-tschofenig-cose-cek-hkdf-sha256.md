---
title: "Encryption Key Derivation in the COSE using HKDF with SHA-256"
abbrev: "Encryption Key Derivation in COSE"
category: std

docname: draft-tschofenig-cose-cek-hkdf-sha256-01
submissiontype: IETF
number:
date:
consensus: true
v: 3
area: Security
workgroup: COSE
keyword:
 - COSE
 - AEAD Downgrade Attack
venue:
  group: COSE
  type: Working Group
  mail: cose@ietf.org
  arch: https://datatracker.ietf.org/wg/cose/about/

author:
  -
    name: Hannes Tschofenig
    org: University of Applied Sciences Bonn-Rhein-Sieg
    abbrev: H-BRS
    email: Hannes.Tschofenig@gmx.net
  -
    name: Russ Housley
    org: Vigil Security, LLC
    abbrev: Vigil Security
    email: housley@vigilsec.com
  -
    name: Ken Takayama
    org: SECOM CO., LTD.
    email: ken.takayama.ietf@gmail.com

normative:
  RFC9052:
  RFC9053:
  RFC9459:
  RFC5869:  
  FIPS180:
    title: "Secure Hash Standard (SHS), FIPS PUB 180-4"
    author:
      org: National Institute of Standards and Technology (NIST)
    date: August 2015
    target: https://csrc.nist.gov/pubs/fips/180-4/upd1/final

informative:
  I-D.ietf-lamps-cms-cek-hkdf-sha256:
  RS2023:
    title: "AEAD-to-CBC Downgrade Attacks on CMS"
    author:
      -
        ins: F. Strenzke
        organization: MTG AG
        name: Falko Strenzke
      -
        ins: J. Roth
        organization: MTG AG
        name: Johannes Roth
    date: November 2023
    target: https://datatracker.ietf.org/meeting/118/materials/slides-118-lamps-attack-against-aead-in-cms
  AEAD-Downgrade:
    title: "Legacy Encryption Downgrade Attacks against LibrePGP and CMS"
    author:
      -
        ins: F. Strenzke
        organization: MTG AG
        name: Falko Strenzke
      -
        ins: J. Roth
        organization: MTG AG
        name: Johannes Roth
    date: July 2024
    target: https://eprint.iacr.org/2024/1110

--- abstract

This document specifies the derivation of the content-encryption key in
CBOR Object Signing and Encryption (COSE). This mechanism protects against
attacks where an attacker manipulates the content-encryption algorithm
identifier.

--- middle

# Introduction

This document specifies the derivation of the content-encryption key
for COSE. The use of this mechanism provides protection against
where the
attacker manipulates the content-encryption algorithm identifier. This
attack has been demonstrated against CMS and the mitigation can be
found in {{I-D.ietf-lamps-cms-cek-hkdf-sha256}}.  This attack is generic
and can apply to other protocols with similar characteristics, such as
COSE. However, the attack requires several preconditions:

1.  The attacker intercepts a COSE Encrypt payload and changes the
    algorithm identifier to use the same underlying cipher with a different
    encryption mode, such as AES-GCM to AES-CBC.

2.  The attacker converts the intercepted content into a "garbage" COSE
Encrypt payload composed of AES-CBC guess blocks.

3.  The attacker sends the "garbage" message to the victim, who then
reveals the result of the decryption to the attacker.

4.  If any of the transformed plaintext blocks match the guess for
    that block, then the attacker learns the plaintext for that
    block.

With highly structured messages, one block can reveal the only
sensitive part of the original message.

This attack is thwarted if the encryption key depends upon the
delivery of the unmodified algorithm identifier.

While {{RFC9459}} requests implementations to use AES-CBC and AES-CTR
in conjunction with an authentication and integrity mechanism,
some recipients may violate it and become victims as a result.
Even the sender uses them with such mechanisms or AEAD cipher
such as AES-GCM, the attacker may remove them or convert the cipher
to non-AEAD such as AES-CBC.

The mitigation for this attack has two parts:

* Potential recipients include a new parameter, cek-hkdf, in the
outermost protected header of the COSE_Encrypt payload to indicate
support for this mitigation. This parameter MUST use the value true.

* Perform encryption with a derived content-encryption key or
content-authenticated-encryption key. The new CEK' is the result
of deriving a CEK. This key derivation uses the alg parameter
found in the outermost COSE_Encrypt header.

~~~
CEK' = HKDF(CEK, COSE_Encrypt.alg)
~~~

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Updated Encryption Flow for each Content Key Distribution Method

This section describes the key distribution and encryption flows on sender side.
Only the payload encryption process will be changed with the mitigation.

Some content key distribution methods generate encrypted CEK (eCEK) from randomly generated CEK.
{{figure-generating-ecek}} shows that each procedure is NOT changed by the mitigation.

~~~aasvg
                  AES-KW                   ECDH+AES-KW     COSE-HPKE
               .---.  .---.               .---.  .---.    .---.  .---.
              | PSK || CEK |             | pkR || skS |  | pkR || skS |
               '-+-'  '-+-'               '-+-'  '-+-'    '-+-'  '-+-'
                 |      |                   v      v        v      v
                 |      |                +------------+   .----------.
                 |      |                |    ECDH    |  |  ContextS  |
                 |      |                +--+---------+   '-+--------'
                 |      |                   v               |
                 |      |                .-----.  .---.     |   .---.
                 |      |               | DH SS || CIS |    |  | aad |
                 |      |                '--+--'  '-+-'     |   '-+-'
                 |      |                   v       v       |  .-'
                 |      |                +------------+     | |
                 |      |                |    HKDF    |     | |
                 |      |                +--+---------+     | |
                 |      |                   |  .---.        | |  .---.
                 |      |                   | | CEK |       | | | CEK |
                 |      |                   |  '-+-'        | |  '-+-'
                 v      v                   v    v          v v    v
               +----------+              +----------+     +----------+
               |   Wrap   |              |   Wrap   |     |   open   |
               +----+-----+              +----+-----+     +----+-----+
                    v                         v                v
                  .----.                    .----.           .----.
                 | eCEK |                  | eCEK |         | eCEK |
                  '----'                    '----'           '----'

PSK   : Pre Shared Key
CEK   : Content Encryption Key
pkR   : Recipient's Public Key
skS   : (Static or Ephemeral) Sender's Private Key
DH SS : DH-Shared Secret
CIS   : COSE Context Information Structure
eCEK  : Encrypted CEK into COSE message
~~~
{: #figure-generating-ecek title="eCEK Generation Flow for each Content Key Distribution Method"}

{{figure-generating-encrypted-payload}} shows that the mitigation layer
is inserted just before the encrypting the plaintext payload.
Note that Enc_structure is fed to encryption function (Encrypt) if the COSE_Encrypt.alg is an AEAD.

~~~aasvg
Direct Direct+KDF AES-KW   Direct ECDH     ECDH+AES-KW     COSE-HPKE
 .---.    .--.    .---.   .---.  .---.        .---.          .---.
| PSK |  | SS |  | CEK | | pkR || skS |      | CEK |        | CEK |
 '-+-'    '-+'    '-+-'   '-+-'  '-+-'        '-+-'          '-+-'
   |        |       |       v      v            |              |
   |        |       |    +------------+         |              |
   |        |       |    |    ECDH    |         |              |
   |        |       |    +--+---------+         |              |
   |     .-'        |       v                   |              |
   |    |  .---.    |    .-----.  .---.         |              |
   |    | | CIS |   |   | DH SS || CIS |        |              |
   |    |  '-+-'    |    '--+--'  '-+-'         |              |
   |    v    v      |       v       v           |              |
   |  +--------+    |    +------------+         |              |
   |  |  HKDF  |    |    |    HKDF    |         |              |
   |  +---+----+    |    +-----+------+         |              |
   v      v         v          v                v              v
+-----------------------------------------------------------------+
|          CEK' = HKDF(CEK, COSE_Encrypt.alg) [Proposal]          |
+--------------------------------+--------------------------------+
                                 v
                            +---------+    .-----------------.
                            | Encrypt |<--+ Plaintext Payload |
                            +----+----+    '-----------------'
                                 v
                        .------------------.
                       | Encrypted Payload  |
                        '------------------'

PSK   : Pre Shared Key
SS    : Shared Secret
CEK   : Content Encryption Key
pkR   : (Static or Ephemeral) Recipient's Public Key
skS   : Sender's Private Key
DH SS : DH-Shared Secret
CIS   : COSE Context Information Structure
~~~
{: #figure-generating-encrypted-payload title="Payload Encryption Flow for each Content Key Distribution Method"}

Then the sender creates COSE_Encrypt0 or COSE_Encrypt structure using these parameters if necessary.

- layer 0: The content encryption layer
  - protected or unprotected headers
    - content encryption algorithm id
    - its parameters such as IV
    - cek-hkdf = true
  - encrypted payload
- layer 1: The content key distribution layer
  - protected or unprotected headers
    - content key distribution method algorithm id
    - its parameters such as ephemeral key
    - kid
  - eCEK

TODO: provide an example binary (in appendix?)

# Updated Decryption Flow for Each Content Key Distribution Method

This section describes the decryption flows on recipient side
for each content key distribution method.

{{figure-decrypting-encrypted-payload}} shows that the mitigation layer
is inserted between the content key distribution methods and content decryption
if the cek-hkdf parameter with true value locates in outer header.
Note that Enc_structure is fed to decryption function (Decrypt) if the COSE_Encrypt.alg is an AEAD.

~~~aasvg
Direct Direct+KDF AES-KW   Direct ECDH     ECDH+AES-KW     COSE-HPKE
 .---.    .--.    .---.   .---.  .---.     .---.  .---.   .---.  .---.
| PSK |  | SS |  | PSK | | pkS || skR |   | pkS || skR | | pkS || skR |
 '-+-'    '-+'    '-+-'   '-+-'  '-+-'     '-+-'  '-+-'   '-+-'  '-+-'
   |        |       |       v      v         v      v       v      v
   |        |       |    +------------+   +------------+  .----------.
   |        |       |    |    ECDH    |   |    ECDH    | |  ContextR  |
   |        |       |    +--+---------+   +--+---------+  '-+--------'
   |    .--'        |       v                v              |
   |   |  .---.     |    .-----.  .---.   .-----.  .---.    |   .---.
   |   | | CIS |    |   | DH SS || CIS | | DH SS || CIS |   |  | aad |
   |   |  '-+-'     |    '--+--'  '-+-'   '--+--'  '-+-'    |   '-+-'
   |   v    v       |       v       v        v       v      |  .-'
   | +--------+     |    +------------+   +------------+    | |
   | |  HKDF  |     |    |    HKDF    |   |    HKDF    |    | |
   | +----+---+  .-'     +-----+------+   +--+---------+    | |
   |      |     | .----.       |             |   .----.     | | .----.
   |      |     || eCEK |      |             |  | eCEK |    | || eCEK |
   |      |     | '--+-'       |             |   '--+-'     | | '--+-'
   |      |     v    v         |             v      v       v v    v
   |      |  +----------+      |           +----------+   +----------+
   |      |  |  Unwrap  |      |           |  Unwrap  |   |   open   |
   |      |  +----+-----+      |           +----+-----+   +----+-----+
   v      v       v            v                v              v
  .----------------------------------------------------------------.
 |                   Content Encryption Key (CEK)                   |
  '-------------------------------+--------------------------------'
                                  v
    +------------------------------------------------------------+
    | CEK' = HKDF(CEK, COSE_Encrypt.alg) if cek-hkdf [Proposal]  |
    +-----------------------------+------------------------------+
                                  v
                             +---------+    .-----------------.
                             | Decrypt |<--+ Encrypted Payload |
                             +----+----+    '-----------------'
                                  v
                         .------------------.
                        | Plaintext Payload  |
                         '------------------'

PSK   : Pre Shared Key
SS    : Shared Secret
pkS   : (Static or Ephemeral) Sender's Public Key
skR   : Recipient's Private Key
CIS   : COSE Context Information Structure
DH SS : DH-Shared Secret
eCEK  : Encrypted CEK in COSE message
~~~
{: #figure-decrypting-encrypted-payload title="Payload Decryption Flow for each Content Key Distribution Method"}

# Use of of HKDF with SHA-256 to Derive Encryption Keys

The mitigation uses the HMAC-based Extract-and-Expand Key Derivation
Function (HKDF) {{RFC5869}} to derive output keying material (OKM) from
input key material (IKM). HKDF is used with the SHA-256 hash
function {{FIPS180}}.

If an attacker were to change the originator-provided COSE_Encrypt
algorithm identifier then the recipient will derive a different
content-encryption key.

The CEK_HKDF function uses the HKDF-Extract and HKDF-
Expand functions to derive the OKM from the IKM:

~~~
Inputs:
  IKM        Input keying material
  alg        COSE_Key algorithm identifier

Output:
  OKM      output keying material (same size as IKM)
~~~

The output OKM is calculated as follows:

~~~
  OKM_SIZE = len(IKM)
  IF OKM_SIZE > 8160 THEN raise error

  salt = "CBOR Object Signing and Encryption"
  PRK = HKDF-Extract(salt, IKM)

  OKM = HKDF-Expand(PRK, alg, OKM_SIZE)
~~~

# Security Considerations

This mitigation always uses HKDF with SHA-256. One KDF algorithm was selected to avoid the need for negotiation. In the future, if a weakness is found in the KDF algorithm, a new attribute will need to be assigned for use with an alternative KDF algorithm.

If the attacker removes the cek-hkdf header parameter from the COSE_Encrypt header prior to delivery to the recipient, then the recipient will not attempt to derive CEK', which will deny the recipient access to the content, but will not assist the attacker in recovering the plaintext content.

If the attacker changes the value of the COSE_Encrypt alg parameter prior to delivery to the recipient, then the recipient will derive a different CEK', which will not assist the attacker in recovering the plaintext content. Providing the algorithm identifer as an input to the key derivation function is sufficient to mitigate the attack described in {{RS2023}}{{AEAD-Downgrade}}, but this mitigation includes both the object identifier and the parameters to protect against some yet-to-be-discovered attack that only manipulates the parameters.

Implementations MUST protect the content-encryption keys, this includes the CEK and CEK'. Compromise of a content-encryption key may result in disclosure of the associated encrypted content. Compromise of a content-authenticated-encryption key may result in disclosure of the associated encrypted content or allow modification of the authenticated content and the additional authenticated data (AAD).

Implementations MUST randomly generate content-encryption keys and content-authenticated-encryption keys. Content key distribution methods are described in Section 8.5 of {{RFC9052}} and in Section 6 of {{RFC9053}}. These algorithms define derivation and protection of content-encryption keys.

# IANA Considerations

IANA is requested to add a new header parameter to the "COSE Common
Header Parameters" established with {{RFC9052}}.

~~~
+-----------+-------+--------------+-------------+------------------+
| Name      | Label | Value Type   | Value       | Description      |
|           |       |              | Registry    |                  |
+-----------+-------+--------------+-------------+------------------+
| cek-hkdf  | TBD   | bool         | N/A         | CEK-HKDF-SHA256  |
+-----------+-------+--------------+-------------+------------------+
~~~

--- back

# Acknowledgments

Add your name here.