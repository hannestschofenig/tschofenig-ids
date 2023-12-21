---
title: Extended Key Update for Transport Layer Security (TLS) 1.3

abbrev: Extended Key Update for TLS
docname: draft-tschofenig-tls-extended-key-update-00
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
      org:
 -
      ins: M. Tuexen
      name: Michael Tuexen
      email: tuexen@fh-muenster.de
      org: Muenster Univ. of Applied Sciences
 -
      ins: T. Reddy
      name: Tirumaleswar Reddy
      email: kondtir@gmail.com
      org: Nokia  

normative:
  RFC2119:
  I-D.ietf-tls-rfc8446bis:
  I-D.ietf-tls-tlsflags:
  RFC9147:
  RFC5869:
informative:
  RFC9325:
  RFC7624:
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
It allows the sender to perform an update of the key and initialization vector
and may trigger the recipient, via the request_update field, to transmit a
key update message in the reverse direction.

In environments where sessions are long-lived, such as industrial IoT or
telecommunication networks, this key update along is insufficient since
perfect forward secrecy is not offered via this mechanism. Earlier versions
of TLS allowed the two peers to perform renegotiation, which is a handshake
that establishes new cryptographic parameters for an existing session.
When a security vulnerability with the renegotiation mechanism was discovered,
RFC 5746 was standardized as a fix. Renegotiation has, however, been removed
from TLS 1.3.

This specification defines an extended key update message that supports
perfect forward secrecy using a Diffie-Hellman key exchange.

--- middle

#  Introduction

The features of TLS and DTLS have changed over the years and while newer versions
optimized and enhanced features (often with the help of extensions) some functionality
was removed without replacement. The ability to update keys and initialization vectors
with forward secrecy has been added in TLS 1.3 {{I-D.ietf-tls-rfc8446bis}} using the
KeyUpdate message and it intended to (partially) replace renegotiation from earlier
TLS versions. The renegotiation feature, while complex, offered additional
functionality that is not supported with TLS 1.3 anymore, including the update
keys with a Diffie-Hellman exchange during the lifetime of a session. If a traffic secret (application_traffic_secret_N) has been compromised, an attacker can passively 
eavesdrop on all future data sent on the connection, including data
encrypted with application_traffic_secret_N+1, application_traffic_secret_N+2, etc.

While such a feature is less relevant in environments with shorter-lived sessions,
such as transactions on the web, there are uses of TLS and DTLS where long-lived
sessions are common. In those environments, such as industrial IoT and
telecommunication networks, availability is important and an interruption of the
communication due to periodic session resumptions is not an option. A full handshake 
with (EC)DHE gives protection against active attackers but prevents the use 
of long-lived sessions.

Some deployments have used IPsec in the past and have now decided to switch to TLS
or DTLS instead and the requirement for updates of cryptographic keys for an existing
session has become a requirement. For IPsec, NIST, BSI, and ANSSI recommends very frequent
re-run of Diffie-Hellman to provide forward secrecy and force attackers to perform a
dynamic key extraction {{RFC7624}}. ANSSI writes "It is recommended to force the periodic
renewal of the keys, e.g., every hour and every 100 GB of data, in order to limit the
impact of a key compromise." {{ANSSI-DAT-NT-003}}.

This specification defines a new, extended key update message supporting perfect
forward secrecy. It does so by utilizing a Diffie-Hellman exchange using one of the
groups negotiated during the initial exchange. The support for this extension is
signaled using the TLS flags extension mechanism. The frequent re-running of extended key

update forces an attacker to do dynamic key exfiltration.

This specification is applicable to both TLS 1.3 {{I-D.ietf-tls-rfc8446bis}} and
DTLS 1.3 {{RFC9147}}. Throughout the specification we do not distinguish between
these two protocols unless necessary for better understanding.

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

To distinguish the key update procedure defined in {{I-D.ietf-tls-rfc8446bis}}
from the key update procedure specified in this document, we use the terms
"classic key update" and "extended key update", respectively.

# Extensions

Client and servers use the TLS flags extension {{I-D.ietf-tls-tlsflags}}
to indicate support for the functionality defined in this document. We
call this the "extended_key_update" extension and the corresponding
flag is called "Extended_Key_Update" flag.

The "Extended_Key_Update" flag proposed by the client in the ClientHello
(CH) MUST be acknowledged in the EncryptedExtensions (EE), if the
server also supports the functionality defined in this document and
is configured to use it.

If the "Extended_Key_Update" flag is not set, servers
ignore any the functionality specified in this document and applications
that require perfect forward security will have to initiate a full handshake.

# Extended Key Update

## Generic Considerations

The ExtendedKeyUpdate handshake message is used to indicate an update
of cryptographic keys. This key update process can be sent by either
peer after it has sent a Finished message.  Implementations that
receive a ExtendedKeyUpdate message prior to receiving a Finished
message MUST terminate the connection with an "unexpected_message"
alert.

The design of the ExtendedKeyUpdate message follows the design of
the classic KeyUpdate message. Both allow the update of keys in
one direction only. However, the ExtendedKeyUpdate message requires
a full-roundtrip due to the nature of the Diffie-Hellman exchange.

The KeyShare entry in the ExtendedKeyUpdate message MUST be the same

group mutually supported by the client and server during the initial
handshake. The peers MUST NOT send a KeyShare Entry in the ExtendedKeyUpdate
message that is not mutually supported by the client and server during 
the initial handshake. An implementation that receives any other value
MUST terminate the connection with an "illegal_parameter" alert.

{{fig-key-update}} showns the interaction graphically.
First, support for the functionality in this specification
is negotiated in the ClientHello and the EncryptedExtensions
messages. Then, the ExtendedKeyUpdate message is sent to
update the application traffic secrets.

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
The sender starts the key update process and the receiver responds
with its key share. The extended key update always consists of two
messages, one from the sender to the receiver and another one from
the receiver to the sender. Both messages use the same format but the
response message MUST NOT have the request_update set to update_requested(1).

The structures for KeyUpdateRequest and KeyShareEntry are defined in
{{I-D.ietf-tls-rfc8446bis}}.

~~~
enum {
    update_not_requested(0), update_requested(1), (255)
} KeyUpdateRequest;

struct {
    KeyUpdateRequest request_update;
    KeyShareEntry key_share;
} ExtendedKeyUpdate;
~~~

If the request_update field is set to "update_requested", then the
receiver MUST send an ExtendedKeyUpdate of its own with request_update set to
"update_not_requested" prior to sending its next Application Data
record.  This mechanism allows either side to force an update to the
entire connection, but causes an implementation which receives
multiple ExtendedKeyUpdate while it is silent to respond with a single
update.  Note that implementations may receive an arbitrary number of
messages between sending a ExtendedKeyUpdate with request_update set to
"update_requested" and receiving the peer's ExtendedKeyUpdate, because those
messages may already be in flight.  However, because send and receive
keys are derived from independent traffic secrets, retaining the
receive traffic secret does not threaten the forward secrecy of data
sent before the sender changed keys.

Note: Implementations may receive an arbitrary number of
messages between one peer sending a ExtendedKeyUpdate and this peer
receiving the peer's ExtendedKeyUpdate, because those
messages may already be in flight. This design aspect needs to be
taken into account when designing APIs that inform applications
using this extended key update procedure to guarantee perfect
forward security.

If implementations independently send their own ExtendedKeyUpdate
messages, and they cross in flight, the result is that each
side increments keys by two generations.

Both sender and receiver MUST encrypt their ExtendedKeyUpdate messages with
the old keys. Both sides MUST enforce that a ExtendedKeyUpdate messages
with the old key is received before accepting any messages encrypted
with the new key. Failure to do so may allow message truncation
attacks.

If a sending
implementation receives a ExtendedKeyUpdate with request_update set to
"update_requested", it MUST NOT send its own ExtendedKeyUpdate if that would
cause it to exceed these limits.  This may result in an eventual need to
terminate the connection when the limits in Section 5.5 of
{{I-D.ietf-tls-rfc8446bis}} are reached.

The ExtendedKeyUpdate and the KeyUpdates MAY be used in combination,
depending on the desired security properties.

## DTLS 1.3-specific Considerations

DTLS 1.3 {{RFC9147}} requires the transmission of an ACK message to ensure
the reliable transmission of the KeyUpdate message. Since the design
of the ExtendedKeyUpdate message always requires a full roundtrip
there is no need for a dedicated ACK message.

{{fig-key-update-dtls}} illustrates an example exchange of the
ExtendedKeyUpdate message used to update traffic secrets in
both directions in a DTLS 1.3 exchange.

~~~
   Client                                             Server

         /-------------------------------------------\
        |             Initial Handshake               |
         \-------------------------------------------/

    [Application Data]         ========>
    (epoch=3)

                               <========      [Application Data]
                                                       (epoch=3)

         /-------------------------------------------\
        |              Some time later ...            |
         \-------------------------------------------/

    [ExtendedKeyUpdate]
    (epoch 3)                  -------->


                               <========      [Application Data]
                                                       (epoch=3)

                                             [ExtendedKeyUpdate]
                               <--------               (epoch=3)

 /----------------------------\
|   Key Update (based on DH)   |
 \----------------------------/

    [Application Data]
    (epoch=4)                  ========>

                               <--------     [ExtendedKeyUpdate]
                                                       (epoch=3)

    [ExtendedKeyUpdate]        -------->
    (epoch=4)

                                /----------------------------\
                               |   Key Update (based on DH)   |
                                \----------------------------/

                               <========      [Application Data]
                                                       (epoch=4)
~~~
{: #fig-key-update-dtls title="DTLS 1.3 Extended Key Update Example."}

In order to facilitate epoch reconstruction in DTLS 1.3 (see
Section 4.2.2 of {{RFC9147}}), implementations MUST NOT send records
with the new keys or send a new ExtendedKeyUpdate messages until the
previous key update has been completed. This avoids having
too many epochs in active use.

Due to loss and/or reordering, DTLS 1.3 implementations may receive a
record with an older epoch than the current one (the requirements
above preclude receiving a newer record).  They SHOULD attempt to
process those records with that epoch (see Section 4.2.2 of {{RFC9147}}
for information on determining the correct epoch) but MAY opt to discard
such out-of-epoch records.

Due to the possibility of a response message of an initial ExtendedKeyUpdate
being lost and thereby preventing the sender of the ExtendedKeyUpdate from
updating its keying material, receivers MUST retain the pre-update keying material
until receipt and successful decryption of a message using the new
keys.

# Updating Traffic Secrets {#key_update}

Once the handshake is complete, it is possible for either side to
update its sending traffic keys using the ExtendedKeyUpdate handshake
message. The next generation of traffic keys is
computed by generating client_/server_application_traffic_secret_N+1
from client_/server_application_traffic_secret_N as described in this
section and then re-deriving the traffic keys, as described in
Section 7.3 of {{I-D.ietf-tls-rfc8446bis}}.

There are three changes to the application_traffic_secret computation
described in {{I-D.ietf-tls-rfc8446bis}}, namely

- The application_traffic_secret_N is not used as an secret as it
may be already exfiltrated by the attacker.
- the label is adjusted to distinguish it from the classic KeyUpdate
message, and
- the Diffie-Hellman derived shared secret, as 'dh-secret', is used
as input to the HKDF-Expand-Label() function to produce the value sk.
sk is subsequently included as a secret value in the computation of
the application_traffic_secret_N+1, making the next generation
traffic key of the application traffic secret dependent on the
DH-derived value.

The next-generation application_traffic_secret is computed as follows:

~~~
sk = HKDF-Extract(0, dh-secret)

application_traffic_secret_N+1 =
    Derive-Secret(sk,"traffic upd 2",
                  application_traffic_secret_N)
~~~

The next generation of traffic keys is computed using the HKDF, as defined in {{RFC5869}}, and

its two components, HKDF-Extract and HKDF-Expand as recommended in Appendix
F.1.1 of {{I-D.ietf-tls-rfc8446bis}}.

Once client_/server_application_traffic_secret_N+1 and its associated
traffic keys have been computed, implementations SHOULD delete
client_/server_application_traffic_secret_N and its associated
traffic keys.

If Hybrid key exchange is used {{I-D.ietf-tls-hybrid-design}}, the two shared
secrets concatenated together (concatenated_shared_secret) is input to
the HKDF-Extract function to produce the value sk.

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
traffic secrets in both direction. Unlike the classic Key Update message
defined in  {{I-D.ietf-tls-rfc8446bis}}, the key update procedure requires
to messages.

# IANA Considerations

IANA is requested to add the following value to the
"TLS Flags" extension defined in {{I-D.ietf-tls-tlsflags}}

*  Value: TBD1

*  Flag Name: extended_key_update

*  Messages: CH, EE

*  Recommended: Y

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
- Michael Tuxen
- Hannes Tschofenig
- K Tirumaleswar Reddy
- Bertrand Rault

Additionally, we would like to thank the chairs of the
Transport and Services Working Group (tsvwg) Gorry Fairhurst and
Marten Seemann as well as the responsible area director Martin Duke.
