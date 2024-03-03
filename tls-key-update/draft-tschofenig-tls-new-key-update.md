---
title: Extended Key Update for Transport Layer Security (TLS) 1.3

abbrev: Extended Key Update for TLS
docname: draft-tschofenig-tls-extended-key-update-01
category: std

ipr: trust200902
area: Security
workgroup: TLS
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
      email: hannes.tschofenig@gmx.net
      org: Siemens
 -
      ins: M. Tüxen
      name: Michael Tüxen
      email: tuexen@fh-muenster.de
      org: Münster Univ. of Applied Sciences
 -
      ins: T. Reddy
      name: Tirumaleswar Reddy
      email: kondtir@gmail.com
      org: Nokia  
 -
      ins: S. Fries
      name: Steffen Fries
      email: steffen.fries@siemens.com
      org: Siemens

normative:
  RFC2119:
  I-D.ietf-tls-rfc8446bis:
  RFC9180:
  RFC9147:
informative:
  RFC9325:
  RFC7296:
  RFC9261:
  RFC5246:
  RFC7624:
  I-D.westerbaan-cfrg-hpke-xyber768d00:
  ANSSI-DAT-NT-003:
     author:
        org: ANSSI
     title: Recommendations for securing networks with IPsec, Technical Report
     target: https://www.ssi.gouv.fr/uploads/2015/09/NT_IPsec_EN.pdf
     date: August 2015
  TLS-Ext-Registry:
     author:
        org: IANA
     title: Transport Layer Security (TLS) Extensions
     target: https://www.iana.org/assignments/tls-extensiontype-values
     date: November 2023

--- abstract

The Transport Layer Security (TLS) 1.3 specification offers a dedicated
message to update cryptographic keys during the lifetime of an ongoing session.
The traffic secret and the initialization vector are updated directionally
but the sender may trigger the recipient, via the request_update field,
to transmit a key update message in the reverse direction.

In environments where sessions are long-lived, such as industrial IoT or
telecommunication networks, this key update alone is insufficient since
forward secrecy is not offered via this mechanism. Earlier versions
of TLS allowed the two peers to perform renegotiation, which is a handshake
that establishes new cryptographic parameters for an existing session.
When a security vulnerability with the renegotiation mechanism was discovered,
RFC 5746 was developed as a fix. Renegotiation has, however, been removed from
version 1.3 leaving a gap in the feature set of TLS.

This specification defines an extended key update that supports forward secrecy.

--- middle

#  Introduction

The features of TLS and DTLS have changed over the years and while newer versions
optimized the protocol and at the same time enhanced features (often with the help
of extensions) some functionality was removed without replacement. The ability to
update keys and initialization vectors has been added in TLS 1.3 {{I-D.ietf-tls-rfc8446bis}}
using the KeyUpdate message and it intended to (partially) replace renegotiation from earlier
TLS versions. The renegotiation feature, while complex, offered additional
functionality that is not supported with TLS 1.3 anymore, including the update
keys with a Diffie-Hellman exchange during the lifetime of a session. If a traffic
secret (referred as application_traffic_secret_N) has been compromised, an attacker
can passively eavesdrop on all future data sent on the connection, including data
encrypted with application_traffic_secret_N+1, application_traffic_secret_N+2, etc.

While such a feature is less relevant in environments with shorter-lived sessions,
such as transactions on the web, there are uses of TLS and DTLS where long-lived
sessions are common. In those environments, such as industrial IoT and
telecommunication networks, availability is important and an interruption of the
communication due to periodic session resumptions is not an option. Re-running a
handshake with (EC)DHE and switching from the old to the new session may be a solution
for some applications but introduces complexity, impacts performance and may lead to
service interruption as well.

Some deployments have used IPsec in the past to secure their communication protocol
and have now decided to switch to TLS or DTLS instead. The requirement for updates of
cryptographic keys for an existing session has become a requirement. For IPsec, NIST,
BSI, and ANSSI recommend to re-run Diffie-Hellman exchanges frequently to provide forward
secrecy and force attackers to perform a dynamic key extraction {{RFC7624}}. ANSSI
writes "It is recommended to force the periodic renewal of the keys, e.g., every
hour and every 100 GB of data, in order to limit the impact of a key compromise."
{{ANSSI-DAT-NT-003}}. While IPsec/IKEv2 {{RFC7296}} offers the desired functionality,
developers often decide to use TLS/DTLS to simplify integration with cloud-based
environments.

This specification defines a new key update mechanism supporting forward
secrecy. It does so by re-using the design approach introduced by the "Exported Authenticators"
specification {{RFC9261}}, which uses the application layer protocol to exchange post-handshake
messages. This approach minimizes the impact on the TLS state machine but places more
burden on application layer protocol designer. To achieve interoperability the payloads
exchanged via the application layer are specified in this document and we make use of
Hybrid Public Key Encryption (HPKE) {{RFC9180}}, which offers an easy migration path
for the integration of post quantum cryptography with its key encapsulation construction
(KEM). Since HPKE requires the sender to possess the recipient's public key, those public
keys need to be exchanged upfront. This specification is silent about
when and how often these public keys are exchanged by the application layer protocol.
Note: To accomplish forward secrecy the public key of the recipient can be only used once.

To leave the exchange of the public keys up to the application is an intentional design decision
to offer flexibility for developers and there is experience with such an approach already from
secure end-to-end messaging protocols. To synchronize the switch to the new traffic secret,
the key updates are directional and accomplished with a new key update message. The trigger
to switch to the new traffic secrets is necessary since the TLS record layer conveys no key
identifier like an epoch or a Connection Identifier (CID).

The support for the functionality described in this specification is signaled using the
TLS extension mechanism. Using the extended key update message frequently forces an attacker
to perform dynamic key exfiltration.

This specification is applicable to both TLS 1.3 {{I-D.ietf-tls-rfc8446bis}} and
DTLS 1.3 {{RFC9147}}. Throughout the specification we do not distinguish between
these two protocols unless necessary for better understanding.

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

To distinguish the key update procedure defined in {{I-D.ietf-tls-rfc8446bis}}
from the key update procedure specified in this document, we use the terms
"key update" and "extended key update", respectively.

This document re-uses the Key Encapsulation Mechanism (KEM) terminology
from RFC 9180 {{RFC9180}}.

The following abbreviations are used in this document:

- KDF: Key Derivation Function
- AEAD: Authenticated Encryption with Associated Data
- HPKE: Hybrid Public Key Encryption

# Negotiating the Extended Key Update

The "extended_key_update" extension is used by the client and the
server to negotiate an HPKE ciphersuite to use, which refers to the
combination of a KEM, KDF, AEAD combination. These HPKE ciphersuites
are communicated in the ClientHello and EncryptedExtensions messages.
The values for the KEM, the KDF, and the AEAD algorithms are taken from
the IANA registry created by {{RFC9180}}.

This extension is only supported with TLS 1.3 {{I-D.ietf-tls-rfc8446bis}}
and newer; if TLS 1.2 {{RFC5246}} or earlier is negotiated, the peers MUST ignore
this extension.

This document defines a new extension type, the extended_key_update(TBD1), as
shown in {{extension-fig}}, which can be used to signal the supported
HPKE ciphersuites for the extended key update message to the peer.

~~~
   enum {
       extended_key_update(TBD1), (65535)
   } ExtensionType;
~~~
{: #extension-fig title="ExtensionType Structure."}

This new extension is populated with the structure shown in {{ciphersuite-fig}}.

~~~
struct {
    uint16 kdf_id;
    uint16 aead_id;
    uint16 kem_id;
} HpkeCipherSuite;

struct {
    HpkeCipherSuite cipher_suites<4..2^16-4>;
} HpkeCipherSuites;
~~~
{: #ciphersuite-fig title="HpkeCipherSuites Structure."}

Whenever it is sent by the client as a ClientHello message extension
({{I-D.ietf-tls-rfc8446bis}}, Section 4.1.2), it indicates what HPKE
ciphersuites it supports.

A server that supports and wants to use the extended key update feature
MUST send the "extended_key_update" extension in the EncryptedExtensions
message indicating what HPKE ciphersuites it prefers to use. The
extension, shown in {{ciphersuite-fig}}, contains a list of supported
ciphersuites in preference order, with the most preferred version first.

The server MUST select one of the ciphersuites from the list offered
by the client. If no suitable ciphersuite is found, the server MUST NOT
return an "extended_key_update" extension to the client.

If this extension is not present, as with any TLS extensions, servers
ignore any the functionality specified in this document and applications
have to rely on the features offered by the TLS 1.3-specified KeyUpdate
instead.

# Using HPKE

To support interoperability between the two endpoints, the following payload
structure is defined.

~~~
struct {
    opaque kid<0..2^16-1>;    
    opaque enc<0..2^16-1>;
    opaque ct<32..2^8-1>;
} HPKE_Payload;
~~~
{: #hpke-payload-fig title="HPKE_Payload Structure."}

The fields have the following meaning:

- kid: The identifier of the recipient public key used for the HPKE
       computation. This allows the sender to indicate what public
       key it used in case it has multiple public keys for a given
       recipient.

- enc: The HPKE encapsulated key, used by the peers to decrypt the
corresponding payload field.

- ct: The ciphertext, which is the result of encrypting a random value,
RAND, with HPKE, as described in {{RFC9180}} using the HPKE SealBase()
operation. RAND MUST be at least 32 bytes long but the maximum length
MUST NOT exceed 255 bytes. This RAND value is input to the
application_traffic_secret generation, as described in {{key_update}}.

This specification MUST use the HPKE Base mode; authenticated HPKE modes
are not supported.

The SealBase() operation requires four inputs, namely

- the public key of the recipient,
- context information (info),
- associated data (aad), and
- plaintext.

SealBase() will return two outputs, "enc" and "ct", which will
be stored in the HPKE_Payload structure.

Two input values for the SealBase() operation require further
explanation:

- The info value MUST be set to the empty string.

- The aad value MUST be populated with the TLS exporter secret.
The exporter interface is described in Section 7.5 of
{{I-D.ietf-tls-rfc8446bis}}. For (D)TLS 1.3, the
exporter_master_secret MUST be used, not the
early_exporter_master_secret.

The exporter value is computed as:

~~~
   TLS-Exporter(label, context_value, key_length) =
       HKDF-Expand-Label(Derive-Secret(Secret, label, ""),
                         "exporter", Hash(context_value), key_length)
~~~

The following values are used for the TLS-Exporter function:

- the label is set to "extended key update client" and
"extended key update server" for extended key updates sent by the
client or server, respectively
- the context_value is set to a zero length value.
- the length of the exported value is equal to the length of
the output of the hash function associated with the selected
ciphersuite.

The recipient will use the OpenBase() operation with the "enc"
and the "ct" parameters received from the sender.  The
"aad" and the "info" parameters are constructed as previously
described for SealBase().

The OpenBase function will, if successful, decrypt "ct".  When
decrypted, the result will either return the random value or an
error.

# Extended Key Update Message {#ext-key-update}

The ExtendedKeyUpdate handshake message is used to indicate that the sender
is updating its sending cryptographic keys.  This message can be sent
by either peer after it has sent a Finished message and exchanged the
necessary public key(s) and HPKE payload(s) by the application layer
protocol. Implementations that receive a ExtendedKeyUpdate message prior
to receiving a Finished message or prior to the exchange of the needed
application layer payloads (public key and HPKE) MUST terminate the
connection with an "unexpected_message" alert.

After sending the ExtendedKeyUpdate message, the sender MUST send all
its traffic using the next generation of keys, computed as described
in {{key_update}}. Upon receiving an ExtendedKeyUpdate message, the
receiver MUST update its receiving traffic keys.

~~~
enum {
    update_not_requested(0), update_requested(1), (255)
} KeyUpdateRequest;

struct {
    opaque kid<0..2^16-1>;
    KeyUpdateRequest request_update;
} ExtendedKeyUpdate;
~~~
{: #extended-key-update-fig title="ExtendedKeyUpdate Structure."}

The kid field indicates the public key of the recipient that was
used by HPKE to encrypt the random value.

The request_update field indicates whether the recipient of the
ExtendedKeyUpdate should respond with its own ExtendedKeyUpdate.
If an implementation receives any other value, it MUST terminate
the connection with an "illegal_parameter" alert.

If the request_update field is set to "update_requested", the
receiver MUST send an ExtendedKeyUpdate of its own with request_update set to
"update_not_requested" prior to sending its next Application Data
record.  This mechanism allows either side to force an update to the
entire connection, but causes an implementation which receives
multiple ExtendedKeyUpdates while it is silent to respond with a single
update.  Note that implementations may receive an arbitrary number of
messages between sending a ExtendedKeyUpdate with request_update set to
"update_requested" and receiving the peer's ExtendedKeyUpdate, because those
messages may already be in flight.

If implementations independently send their own ExtendedKeyUpdate with
request_update set to "update_requested", and they cross in flight,
then each side will also send a response, with the result that each
side increments by two generations.

The sender MUST encrypt ExtendedKeyUpdate messages with the old keys
and the receiver MUST decrypt ExtendedKeyUpdate messages with the old
keys. Senders MUST enforce that ExtendedKeyUpdate encrypted with the
old key is received before accepting any messages encrypted with the
new key.

If a sending implementation receives a ExtendedKeyUpdate with request_update
set to "update_requested", it MUST NOT send its own ExtendedKeyUpdate if
that would cause it to exceed these limits and SHOULD instead ignore the
"update_requested" flag.

The ExtendedKeyUpdate and the KeyUpdates MAY be used in combination.

# Updating Traffic Secrets {#key_update}

The ExtendedKeyUpdate handshake message is used to indicate that
the sender is updating its sending cryptographic keys.  This message can
be sent by either endpoint after three conditions are met:

- The endpoint has sent a Finished message.
- The endpoint is configured with a public key of the recipient. The process
for exchanging and updating these public keys is application-specific.
- The endpoint has conveyed the HPKE payload at the application
layer to the peer. HPKE is used to securely exchange a random number
using a KEM.

The next generation of traffic keys is computed as described in this
section. The traffic keys are derived, as described in
Section 7.3 of {{I-D.ietf-tls-rfc8446bis}}.

There are two changes to the application_traffic_secret computation
described in {{I-D.ietf-tls-rfc8446bis}}, namely

- the label is adjusted to distinguish it from the regular KeyUpdate
message, and
- the random value, which was securely exchanged between the two
endpoints, is included in the generation of the application
traffic secret.

The next generation application_traffic_secret is computed as:

~~~
application_traffic_secret_N+1 =
    HKDF-Expand-Label(RAND,
                      "traffic up2", "", Hash.length)
~~~

Once client_/server_application_traffic_secret_N+1 and its associated
traffic keys have been computed, implementations SHOULD delete
client_/server_application_traffic_secret_N and its associated
traffic keys.

# Example

{{fig-key-update}} shows the interaction between a TLS 1.3 client
and server graphically. This section shows an example message exchange
where a client updates its sending keys.

There are three phases worthwhile to highlight:

1. First, the support for the functionality in this specification
is negotiated in the ClientHello and the EncryptedExtensions
messages. As a result, the two peers have a shared understanding
of the negotiated HPKE ciphersuite, which includes a KEM, a KDF,
and an AEAD.

2. Once the initial handshake is completed, application layer
payloads can be exchanged. The two peers exchange public keys
suitable for use with the HPKE KEM and subsequently an HPKE-
encrypted random value.

3. When a key update needs to be triggered by the application,
it instructs the (D)TLS stack to transmit an ExtendedKeyUpdate
message.

{{fig-key-update}} provides an overview of the exchange starting
with the initial negotiation followed by the key update, which
involves the application layer interaction.

~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share
     | + signature_algorithms
     v + extended_key_update   -------->
                                                  ServerHello  ^ Key
                                                  + key_share  | Exch
                                                               v
                                        {EncryptedExtensions   ^ Server
                                       + extended_key_update}  | Params
                                         {CertificateRequest}  v
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------           
     ^ {Certificate
Auth | {CertificateVerify}
     v {Finished}              -------->
                                  ...
                              some time later
                                  ...
  +---------------- Application Layer Exchange --------------+
  |                                                          |
  |     (a)  Sender sends public key to the client           |
  |                                                          |
  |     (b)  Client uses HPKE to generate enc and ct         |
  |                                                          |
  |     (c)  Client sents enc and ct to the server           |
  |                                                          |
  |     (d)  Client triggers the extended key update         |
  |          at the TLS layer                                |
  |                                                          |
  +---------------- Application Layer Exchange --------------+

       [ExtendedKeyUpdate]     -------->
                               <--------  [ExtendedKeyUpdate]
~~~
{: #fig-key-update title="Extended Key Update Message Exchange."}

For the server to generate and transmit a public key it is
necessary to determine whether the extended key update extension
has been negotiated success and what HPKE ciphersuite was
selected. This information can be obtained by the application
by using the "Get HPKE Ciphersuite" API.

Once the public key has been sent to the client, it can use the
"Encapsulate" API with SealBase(pk, info, aad, rand) to produce
enc, and ct. A random value has to be passed into the API call.

The client transmit the enc, and ct values to the server, which
performs the reverse operation using the "Decapsulate" API with
OpenBase(enc, skR, info, aad, ct) returning the random value.

The server uses the "Update-Prepare" API to get the (D)TLS stack
ready for a key update.

When the client wants to switch to the new sending key it uses the
"Update-Trigger" API to inform the (D)TLS library to trigger the
transmission of the ExtendedKeyUpdate message.

#  DTLS 1.3 Considerations

As with other handshake messages with no built-in response, the
ExtendedKeyUpdate MUST be acknowledged.  In order to facilitate
epoch reconstruction implementations MUST NOT send records with
the new keys or send a new ExtendedKeyUpdate until the previous
ExtendedKeyUpdate has been acknowledged (this avoids having too
many epochs in active use).

Due to loss and/or reordering, DTLS 1.3 implementations may receive a
record with an older epoch than the current one (the requirements
above preclude receiving a newer record). They SHOULD attempt to
process those records with that epoch but MAY opt to discard
such out-of-epoch records.

Due to the possibility of an ACK message for an ExtendedKeyUpdate
being lost and thereby preventing the sender of the ExtendedKeyUpdate
from updating its keying material, receivers MUST retain the
pre-update keying material until receipt and successful decryption
of a message using the new keys.

# API Considerations

The creation and processing of the extended key update messages SHOULD be
implemented inside the (D)TLS library even if it is possible to implement
it at the application layer. (D)TLS implementations supporting the use of
the extended key update SHOULD provide application programming interfaces
by which clients and server may request and process the extended key update
messages.

It is also possible to implement this API outside of the (D)TLS library.
This may be preferable in cases where the application does not have
access to a TLS library with these APIs or when TLS is handled independently
of the application-layer protocol.

All APIs MUST fail if the connection uses a (D)TLS version of 1.2 or earlier.

The following sub-sections describe APIs that are considered necessary to
implement the extended key update functionality but the description is
informative only.

## The "Get HPKE Ciphersuite" API

This API allows the application to determine the negotiated HPKE ciphersuite
from the (D)TLS stack. This information is useful for the application since
it needs to exchange or present public keys to the stack.

It takes a reference to the initial connection as input and returns the
HpkeCipherSuite structure (if the extension was successfully negotiated)
or an empty payload otherwise.

## The "Encapsulate" API

This API allows the application to request the (D)TLS stack to execute HPKE
SealBase operation. It takes the following values as input:

* a reference to the initial connection
* public key of the recipient
* HPKE ciphersuite
* Random value

It returns the {{hpke-payload-fig}} payload.

## The "Decapsulate" API

This API allows the application to request the (D)TLS stack to execute HPKE
OpenBase operation. It takes the following values as input:

* a reference to the initial connection
* a reference to the secret key corresponding to the previously exchanged public key
* the {{hpke-payload-fig}} payload

It returns the random value, in case of success.

## The "Update-Prepare" API

This API allows the application to request the (D)TLS stack to execute HPKE
OpenBase operation. It takes the following values as input:

* a reference to the initial connection
* the random value obtained from the "Decapsulate" API call

It returns the success or failure.

## The "Update-Trigger" API

This API allows the application to request the (D)TLS stack to initiate
an extended key update using the message defined in {{ext-key-update}}.

It takes an identifier to the public key of the recipient as input and
returns success or failure.

# Post-Quantum Considerations

Hybrid key exchange refers to using multiple key exchange algorithms
simultaneously and combining the result with the goal of providing
security even if all but one of the component algorithms is broken.
It is motivated by transition to post-quantum cryptography.  HPKE can
be extended to support hybrid post-quantum Key Encapsulation
Mechanisms (KEMs), as defined in {{I-D.westerbaan-cfrg-hpke-xyber768d00}}

#  Security Considerations

{{RFC9325}} provides a good summary of what (perfect) forward secrecy
is and how it relates to the TLS protocol. In summary, it says:

"Forward secrecy (also called "perfect forward secrecy" or "PFS") is a
defense against an attacker who records encrypted conversations where
the session keys are only encrypted with the communicating parties'
long-term keys. Should the attacker be able to obtain these long-term
keys at some point later in time, the session keys and thus the entire
conversation could be decrypted."

Appendix F of {{I-D.ietf-tls-rfc8446bis}} goes into details of
explaining the security properties of the TLS 1.3 protocol and notes
"... forward secrecy without rerunning (EC)DHE does not stop an attacker
from doing static key exfiltration." It concludes with a recommendation
by saying: "Frequently rerunning (EC)DHE forces an attacker to do dynamic
key exfiltration (or content exfiltration)." (The term key exfiltration
is defined in {{RFC7624}}.)

This specification re-uses public key encryption to update application
traffic secrets in one direction. Hence, updates of these application
traffic secrets in both directions requires two ExtendedKeyUpdate messages.

To perform public key encryption the sender needs to have access to the
public key of the recipient. This document makes the assumption that the
public key in the exchanged end-entity certificate can be used with the
HPKE KEM. The use of HPKE, and the recipients long-term public key, in
the ephemeral-static Diffie-Hellman exchange provides perfect forward
secrecy of the ongoing connection and demonstrates possession of the
long-term secret key.

# IANA Considerations

IANA is also requested to allocate a new value in the "TLS ExtensionType Values"
subregistry of the "Transport Layer Security (TLS) Extensions"
registry {{TLS-Ext-Registry}}, as follows:

*  Value: TBD1

*  Extension Name: extended_key_update

*  TLS 1.3: CH, EE

* DTLS-Only: N

* Recommended: Y

*  Reference: [This document]

IANA is also requested to allocate a new value in the "TLS
HandshakeType" subregistry of the "Transport Layer Security (TLS)
Extensions" registry {{TLS-Ext-Registry}}, as follows:

*  Value: TBD2

*  Description: ExtendedKeyUpdate

* DTLS-OK: Y

*  Reference: [This document]

--- back

# Acknowledgments

We would like to thank the members of the "TSVWG DTLS for SCTP
Requirements Design Team" for their discussion. The members, in
no particular order, are:

- Marcelo Ricardo Leitner
- Zaheduzzaman Sarker
- Magnus Westerlund
- John Mattsson
- Claudio Porfiri
- Xin Long
- Michael Tuexen

Additionally, we would like to thank the chairs of the
Transport and Services Working Group (tsvwg) Gorry Fairhurst and
Marten Seemann as well as the responsible area director Martin Duke.

Finally, we would like to thank Martin Thomson, Ilari Liusvaara,
Benjamin Kaduk, Scott Fluhrer, Dennis Jackson, David Benjamin,
and Thom Wiggers for a review of an initial version of this
specification.

# Design Rational {#rational}

The design in this document is motivated by long-lived TLS connections,
which can be observed in, at least, two use cases: industrial IoT
environments and telecommunication operator networks. In the discussions
the desire to develop a design that is also compatible with the ongoing
work on PQC algorithm and the use of KEMs in particular.

HPKE was selected as a building block due to its popularity in IETF
protocols and the availability of implementations. The core building
blocks of HPKE (a KEM and a key derivation function) could, howerver,
be used directly as well.

The design presented in this document utilizes HPKE with the Seal/Open
API calls instead of utilizing Encap/Decap API calls directly. Available
HPKE libraries expose the former API calls and this simplifies the
implementation of the solution described in this document. As a
side-effect, context information can also be passed into these API calls.

The downside of using the currently documented approach is the need to
additionally encrypt plaintext, which in our case is a random value. It
may also introduce complexity with the integration of hybrid approach.

The use of application layer protocol messages to exchange TLS handshake
messages is motiviated by the desire to reduce the impact on the TLS
state machine but also by the prior work on post-handshake authentication
using "Exported Authenticators". A design that exchanges messages
at the TLS layer is possible but raises the question about whether
post-handshake authentication messages should also be exchanged at
the TLS layer to accomplish some level of uniformity. Even the re-
introduction of session renegotation, a feature removed with TLS 1.3,
may seem worthwhile to consider.
