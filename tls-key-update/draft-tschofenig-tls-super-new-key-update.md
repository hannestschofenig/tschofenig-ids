---
title: Extended Key Update for Transport Layer Security (TLS) 1.3

abbrev: Extended Key Update for TLS
docname: draft-tschofenig-tls-extended-key-update-02
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
  RFC9147:
  I-D.ietf-tls-tlsflags:
informative:
  RFC9325:
  RFC7296:
  RFC9261:
  RFC5246:
  RFC7624:
  I-D.connolly-tls-mlkem-key-agreement:
  I-D.ietf-tls-hybrid-design:
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
keys with a Diffie-Hellman exchange during the lifetime of a session.

There are use cases of TLS and DTLS where long-lived sessions are common. In those
environments, such as industrial IoT and telecommunication networks, availability
is important and an interruption of the communication due to periodic session
resumptions is not an option. Re-running a handshake with (EC)DHE and switching from
the old to the new session may be a solution for some applications but introduces
complexity, impacts performance and may lead to service interruption as well.

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

This specification defines a new, extended key update message supporting perfect
forward secrecy.  It does so by utilizing a Diffie-Hellman exchange using one of
the groups negotiated during the initial exchange.  The support for this extension
is signaled using the TLS flags extension mechanism.  The frequent re-running of
extended key update forces an attacker to do dynamic key exfiltration.

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

# Key Exfiltration and Forward Secrecy

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
from doing static key exfiltration". It concludes with a recommendation
by saying: "Frequently rerunning (EC)DHE forces an attacker to do dynamic
key exfiltration (or content exfiltration)." The terms static and dynamic
key exfiltration are defined in {{RFC7624}}. Dynamic key exfiltration,
refers to attacks in which the collaborator delivers keying material to
the attacker frequently, e.g., on a per-session basis. Static key
exfiltration means that the transfer of keys happens once or rarely
and that the transferred key is typically long-lived.

# Negotiating the Extended Key Update

Client and servers use the TLS flags extension
{{I-D.ietf-tls-tlsflags}} to indicate support for the functionality
defined in this document.  We call this the "extended_key_update"
extension and the corresponding flag is called "Extended_Key_Update"
flag.

The "Extended_Key_Update" flag proposed by the client in the
ClientHello (CH) MUST be acknowledged in the EncryptedExtensions
(EE), if the server also supports the functionality defined in this
document and is configured to use it.

If the "Extended_Key_Update" flag is not set, servers ignore any the
functionality specified in this document and applications that
require perfect forward security will have to initiate a full
handshake.

# Extended Key Update Message {#ext-key-update}

The ExtendedKeyUpdate handshake message is used to indicate an update
of cryptographic keys. This key update process can be sent by either
peer after it has sent a Finished message.  Implementations that
receive a ExtendedKeyUpdate message prior to receiving a Finished
message MUST terminate the connection with an "unexpected_message"
alert.

The KeyShare entry in the ExtendedKeyUpdate message MUST be the same
group mutually supported by the client and server during the initial
handshake. The peers MUST NOT send a KeyShare Entry in the ExtendedKeyUpdate
message that is not mutually supported by the client and server during 
the initial handshake. An implementation that receives any other value
MUST terminate the connection with an "illegal_parameter" alert.

{{fig-key-update}} shows the interaction graphically.
First, support for the functionality in this specification
is negotiated in the ClientHello and the EncryptedExtensions
messages. Then, the ExtendedKeyUpdate exchange is sent to
update the application traffic secrets. Send and receive
keys are derived from independent traffic secrets, retaining the
receive traffic secret does not threaten the forward secrecy of data
sent before the sender changed keys.

~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share
     | + signature_algorithms
     v + Extended_Key_Update       -------->
                                                  ServerHello  ^ Key
                                                  + key_share  | Exch
                                                               v
                                        {EncryptedExtensions   ^ Server
                                       + Extended_Key_Update}  | Params
                                         {CertificateRequest}  v
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------           
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
                                  ...
       [ExtendedKeyUpdate]     -------->
                               <--------  [ExtendedKeyUpdate]
                                  ...
       [ExtendedKeyUpdate]     <-------
                               -------->  [ExtendedKeyUpdate]
                                  ...
       [Application Data]      <------->  [Application Data]
~~~
{: #fig-key-update title="Extended Key Update Message Exchange."}

The structure of the ExtendedKeyUpdate message is shown below.

~~~
struct {
  KeyShareEntry key_share;
} ExtendedKeyUpdateRequest;

struct {
  KeyShareEntry key_share;
} ExtendedKeyUpdateResponse;

struct {
} NewKeyUpdate;
~~~

key_exchange:  Key exchange information.  The contents of this field
  are determined by the specified group and its corresponding
  definition. The structures are defined in {{I-D.ietf-tls-rfc8446bis}}.

The extended key update process is performed between the initiator and the
responder as follows:

1. Initiator sends a ExtendedKeyUpdateRequest message, which contains
a key share. While an extended key update is in progress, the initiator
MUST NOT initiate further key updates.

2. On receipt of the ExtendedKeyUpdateRequest message, the responder 
sends the ExtendedKeyUpdateResponse message. This message contains the
key share of the responder. While an extended key update is in progress,
the responder MUST NOT initiate further key updates.

3. On receipt of the ExtendedKeyUpdateResponse message, the initiator
is able to derive a secret key based on the exchanged key shares. 
After sending a NewKeyUpdate message, the initiator MUST update its
traffic keys and MUST send all its traffic using the next generation of keys.

4. On receipt of the NewKeyUpdate message by the responder, it MUST update
its receive keys. In response, the responder transmits a NewKeyUpdate message
and MUST update its sending keys.

Both sender and receiver MUST encrypt their NewKeyUpdate messages with
the old keys. Additionally, both sides MUST enforce that a NewKeyUpdate
with the old key is received before accepting any messages encrypted
with the new key.

If implementations independently initiate the extended key update
procedure, and they cross in flight, the result is that each side
increments keys by two generations.

~~~
      struct {
          HandshakeType msg_type;    /* handshake type */
          uint24 length;             /* bytes in message */
          select (Handshake.msg_type) {
              case client_hello:          ClientHello;
              case server_hello:          ServerHello;
              case end_of_early_data:     EndOfEarlyData;
              case encrypted_extensions:  EncryptedExtensions;
              case certificate_request:   CertificateRequest;
              case certificate:           Certificate;
              case certificate_verify:    CertificateVerify;
              case finished:              Finished;
              case new_session_ticket:    NewSessionTicket;
              case key_update:            KeyUpdate;
              case extended_key_update:   ExtendedKeyUpdate;
          };
      } Handshake;
~~~
{: #fig-handshake title="Handshake Structure."}

The ExtendedKeyUpdate and the KeyUpdates MAY be used in combination
over the lifetime of a TLS communication session, depending on the
desired security properties.

# Updating Traffic Secrets {#key_update}

The ExtendedKeyUpdate handshake message is used to indicate that
the sender is updating its sending cryptographic keys.  This message can
be sent by either endpoint after the Finished messages have been exchanged.

The next generation of application_traffic_secret is computed as follows:

~~~
application_traffic_secret_N+1 =
    HKDF-Expand-Label(SK,
                      "traffic up2", "", Hash.length)                   
~~~

There are two changes to the application_traffic_secret computation
described in {{I-D.ietf-tls-rfc8446bis}}, namely

- the label is adjusted to distinguish it from the regular KeyUpdate
message, and
- the SK value, which was derived between the two endpoints, is included
in the generation of the application traffic secret.

Once client_/server_application_traffic_secret_N+1 and its associated
traffic keys have been computed, implementations SHOULD delete
client_/server_application_traffic_secret_N and its associated
traffic keys.

# Example

{{fig-key-update}} shows the interaction between a TLS 1.3 client
and server graphically. This section shows an example message exchange
where a client updates its sending keys.

There are two phases:

1. The support for the functionality in this specification
is negotiated in the ClientHello and the EncryptedExtensions
messages.

2. Once the initial handshake is completed, a key update can be
triggered.

{{fig-key-update}} provides an overview of the exchange starting
with the initial negotiation followed by the key update.

~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share
     | + signature_algorithms
     v + extended_key_update
                             -------->
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
 [ExtendedKeyUpdateRequest]    -------->
  (with KeyShare)
                               <-------- [ExtendedKeyUpdateResponse]
                                           (with KeyShare)
 [NewKeyUpdate]                -------->
                               <-------- [NewKeyUpdate]
~~~
{: #fig-key-update title="Extended Key Update Message Exchange."}

#  DTLS 1.3 Considerations

Due to the possibility of a NewKeyUpdate message being lost and
thereby preventing the sender of the NewKeyUpdate message
from updating its keying material, receivers MUST retain the
pre-update keying material until receipt and successful decryption
of a message using the new keys.

Due to loss and/or reordering, DTLS 1.3 implementations may receive a
record with an older epoch than the current one. They SHOULD attempt to
process those records with that epoch but MAY opt to discard
such out-of-epoch records.

# Post-Quantum Cryptogrphy Considerations

Hybrid key exchange refers to using multiple key exchange algorithms
simultaneously and combining the result with the goal of providing
security even if all but one of the component algorithms is broken.
It is motivated by transition to post-quantum cryptography. TLS supports
the hybrid key exchange based on the extension defined in
{{I-D.connolly-tls-mlkem-key-agreement}}. PQC algorithms can also be
exchanged in key shares, as described in {{I-D.ietf-tls-hybrid-design}}.

#  Security Considerations

This entire document is about security.

When utilizing this extension it is important to understand the interaction
with ticket-based resumption since resumption without the execution of
a Diffie-Hellman exchange offering forward secrecy will potentially undo
updates to the application traffic secret derivation, depending on when
tickets have been exchanged. 

# IANA Considerations

IANA is requested to add the following entry to the "TLS Flags"
extension registry {{TLS-Ext-Registry}}:

*  Value: TBD1

*  Flag Name: extended_key_update

*  Messages: CH, EE

*  Recommended: Y

*  Reference: [This document]

IANA is requested to add the following entry to the "TLS
HandshakeType" registry {{TLS-Ext-Registry}}:

*  Value: TBD2

*  Description: extended_key_update

*  DTLS-OK: Y

*  Reference: [This document]

*  Comment:


--- back

# Acknowledgments

We would like to thank the members of the "TSVWG DTLS for SCTP
Requirements Design Team" for their discussion. The members, in
no particular order, were:

*  Marcelo Ricardo Leitner
*  Zaheduzzaman Sarker
*  Magnus Westerlund
*  John Mattsson
*  Claudio Porfiri
*  Xin Long
*  Michael Tüxen
*  Hannes Tschofenig
*  K Tirumaleswar Reddy
*  Bertrand Rault

Additionally, we would like to thank the chairs of the
Transport and Services Working Group (tsvwg) Gorry Fairhurst and
Marten Seemann as well as the responsible area director Martin Duke.

Finally, we would like to thank Martin Thomson, Ilari Liusvaara,
Benjamin Kaduk, Scott Fluhrer, Dennis Jackson, David Benjamin,
and Thom Wiggers for a review of an initial version of this
specification.
