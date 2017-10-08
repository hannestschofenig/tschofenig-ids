---
title: The Datagram Transport Layer Security (DTLS) Connection Identifier
abbrev: DTLS Connection ID
docname: draft-rescorla-tls-dtls-connection-id-latest
category: std
obsoletes: 6347

ipr: pre5378Trust200902
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
       ins: E. Rescorla
       name: Eric Rescorla
       organization: RTFM, Inc.
       role: editor
       email: ekr@rtfm.com

 -
       ins: H. Tschofenig
       name: Hannes Tschofenig
       organization: ARM Limited
       role: editor
       email: hannes.tschofenig@arm.com

normative:
  RFC2119: 
  I-D.ietf-tls-dtls13:
  RFC6347:
  RFC5246: 
informative:
  RFC6973:
--- abstract

This document specifies the "Connection ID" concept for the Datagram Transport Layer Security 
(DTLS) protocol, version 1.2 and version 1.3.

A Connection ID is an identifier carried in the record layer header that gives the 
recipient additional information for selecting the appropriate security association.
In "classical" DTLS selecting a security association of an incoming DTLS record 
is accomplished with the help of the 5-tuple. If the source IP addres and/or 
source port changes during the lifetime of an ongoing DTLS session changes then the
receiver will be unable to locate the correct security security context. 

--- middle


#  Introduction

The Datagram Transport Layer Security (DTLS) protocol was designed for securing 
connection-less transports, like UDP. DTLS, like TLS, starts with a handshake, 
which can be computationally demanding (particularly when public key cryptography 
is used). After a successful handshake symmetric key cryptography is used to 
apply data origin authentication, integrity and confidentiality protection. This 
two-step approach allows to amortize the cost of the initial handshake to subsequent
application data protection. Ideally, the second phase where application data is
protected lasts over a longer period of time since the established keys will only 
need to be updated once the key lifetime expires. In DTLS this key lifetime is not 
explicitly negotiated but instead determined by the time nonce re-use happens. 

Unfortunately, in some deployments the handshake may need to be re-run under certain 
circumstances. In Internet of Things deployments it may, for example, happen that a 
device needs to enter extended sleep periods to increase the battery lifetime. During 
such a sleep period the device does not transmit any data packets and NAT bindings 
may expire. Whenever the device re-connects the NAT may allocate a new NAT binding, 
which will lead to a failure to retrieve the correct security context by the receiver. 

As a solution, this document introduces two extensions, namely: 

- the "connection_id" extension used in the ClientHello and ServerHello, and 
- the "cid" field in the record layer header. 

In a nutshell, the "connection_id" extension allows the DTLS client to indicate support 
for this feature and to propose a connection id value used by the DTLS server for any 
packets sent to the client. The DTLS server returns the "connection_id" extension 
if it supports this feature, and is willing to use it. It will also propose a connection 
id value to be used by client for any packets sent to the server. 

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The reader is assumed to be familiar with the DTLS specifications since this 
document defines an extension to DTLS 1.2 and DTLS 1.3.

# Record Layer Extensions

This extension is applicable for use with DTLS 1.2 and DTLS 1.3. This extension
can be used with the optimized DTLS 1.3 record layer format. The newly introduced
"cid" field is 48 bits long to allow for a sophisticated number of concurrent 
connections. 

{{dtls-record12}} and {{dtls-record13}} illustrate the record formats of DTLS 1.2 
and DTLS 1.3, respectively. 

~~~~
  struct {
     ContentType type;
     ProtocolVersion version;
     uint16 epoch;
     uint48 sequence_number;
     uint48 cid;            // New field
     uint16 length;
     select (CipherSpec.cipher_type) {
        case block:  GenericBlockCipher;
        case aead:   GenericAEADCipher;
     } fragment;
  } DTLSCiphertext;
~~~~
{: #dtls-record12 title="DTLS 1.2 Record Format with Connection ID"}

~~~~
  struct {
     opaque content[DTLSPlaintext.length];
     ContentType type;
     uint8 zeros[length_of_padding];
  } DTLSInnerPlaintext;

  struct {
     ContentType opaque_type = 23; /* application_data */
     ProtocolVersion legacy_record_version = {254,253); // DTLSv1.2
     uint16 epoch;                         // DTLS-related field
     uint48 sequence_number;               // DTLS-related field
     uint48 cid;                           // New field
     uint16 length;
     opaque encrypted_record[length];
  } DTLSCiphertext;
~~~~
{: #dtls-record13 title="DTLS 1.3 Record Format with Connection ID"}

Besides the "cid" field, all other fields are defined in the DTLS 1.2 and
DTLS 1.3 specifications. 

# The "connection_id" Extension

This document defines a new extension type (connection_id(TBD)), which
is used in ClientHello and ServerHello messages of the DTLS 1.2. For 
DTLS 1.3 the ClientHello and the EncryptedExtensions messages are used 
instead offering better privacy protection. 

The extension type is specified as follows.

~~~~
  enum {
     connection_id(TBD), (65535)
  } ExtensionType;
~~~~

The extension_data field of this extension, when included in the
ClientHello, MUST contain the CID structure. Whenever multiple IDs are 
included they MUST refer to the same security association. This allows 
switching to a different connection id to increase unlinkability. It 
is up to the client and the server to decide how many connection ids 
to allocate for a single DTLS session. 

~~~~
  struct {
     select (type) {
        case client:
           uint48 cid<1..2^8-1>;
        case server:
           uint48 cid<1..2^8-1>;
     } body;
  } connection_id;
~~~~

The design rational for the design is as follows: 

1. Multiple Connection IDs: This specification allows each peer to allocate 
more than one connection id to a single DTLS session. This is useful in those 
cases where a client wants to avoid sessions being correlated by an eavesdropper. 

2. The length of the cid field was chosen to be 48 bytes, which is long enough 
to allow for many concurrent connections and short enough not to bloat the record 
format. The fixed length encoding was chosen for convenient parsing. 

3. Previous design ideas for using cryptographically generated session ids, either using hash 
chains or public key encryption, were dismissed due to their inefficient 
designs. Note that a client always has the chance to fall-back to a full handshake 
or more precisely to a handshake that uses session resumption (DTLS 1.2 language) or 
to a PSK-based handshake using the ticket-based approach. 

4. Connection ids are exchanged at the beginning of the DTLS session only. There is no 
dedicated "connection id update" message that allows new connection ids to be established mid-session. 
This contributes to a simpler design but removes some flexibility. 

5. DTLS 1.2 peers switch to the new record layer format when encryption is enabled. The 
same is true for DTLS 1.3 but since the DTLS 1.3 enables encryption early in the handshake phase the 
cid concept will be enabled earlier. 

# Example 

Below is an example exchange for DTLS 1.3 using a single 
connection id in each direction. 

~~~~
Client                                             Server
------                                             ------

ClientHello 
(connection_id=5)
                            -------->


                            <--------       HelloRetryRequest
                                                     (cookie)

ClientHello                 -------->
(connection_id=5)
  +cookie

                            <--------             ServerHello
                                          EncryptedExtensions
                                          (connection_id=100)
                                                  Certificate 
                                            CertificateVerify 
                                                     Finished

Certificate                -------->
CertificateVerify
Finished 

                           <--------                      Ack 

Application Data           ========>
(cid=100)

                           <========         Application Data
                                                      (cid=5)
~~~~
{: #dtls-example title="Example DTLS Exchange with Connection IDs"}

#  Security and Privacy Considerations

The connection id replaces the previously used 5-tuple and, as such, introduces
an identifier that remains persistent during the lifetime of a DTLS session. 
Every identifier introduces the risk of linkability, as explained in {{RFC6973}}.

An on-path adversary, who is able to observe the DTLS 1.2 protocol exchanges between the 
DTLS client and the DTLS server, is able to link the initial handshake to all 
subsequent payloads carrying the same connection id pair (for bi-directional
communication). For DTLS 1.3 the server-provided connection id is encrypted during 
the handshake but it will be trivial for an adversary to correlate packets belonging 
to the same session with the help of the transport layer header and DTLS record header. 

Without multi-homing and mobility the use of the connection id is not different to the 
use of the 5-tuple. With multi-homing an adversary is able to correlate the communication 
interaction over the two paths, which adds further privacy concerns. 

The primary use case for this extension is for IoT devices where the battery lifetime 
is a concern and where the cost of re-running the full DTLS handshake or an abbreviated 
handshake is prohibitive (for example due to the energy requirements of the additional 
handshake, or the bandwidth needed by the additional messaging). The abbreviated handshake
would use session resumption or session ticket in DTLS 1.2 or the revised ticket concept in DTLS 1.3. 
Note that DTLS 1.3 lowers the cost of an abbreviated handshake due to the use of the 0-RTT exchange. 

When there are privacy concerns the authors recommend to allocate (and exchange) a pool
of connection ids so that the client can switch ids. Switching of ids can happen, for
example, when certain events occur (like switching from one interface to another one in a multi-homing environment).

This document does not change the security properties of DTLS 1.2 {{RFC6347}} and DTLS 1.3 {{I-D.ietf-tls-dtls13}}. 
It merely provides a more robust mechanism for associating an incoming packet with a store security context.

#  IANA Considerations

   IANA is requested to allocate an entry to the existing TLS "ExtensionType Values"
   registry, defined in {{RFC5246}}, for connection_id(TBD) defined in this
   document.

--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

draft-rescorla-tls-dtls-connection-id-00

  - Initial version

# Working Group Information

The discussion list for the IETF TLS working group is located at the e-mail
address <tls@ietf.org>. Information on the group and information on how to
subscribe to the list is at <https://www1.ietf.org/mailman/listinfo/tls>

Archives of the list can be found at:
<https://www.ietf.org/mail-archive/web/tls/current/index.html>

# Contributors

Many people have contributed to this specification since the functionality has
been highly desired by the IoT community. We would like to thank the following 
individuals for their contributions in earlier specifications:

~~~ 
* Thomas Fossati
  Nokia
  thomas.fossati@nokia.com
~~~

~~~ 
* Nikos Mavrogiannopoulos
  RedHat
  nmav@redhat.com
~~~

Additionally, we would like to thank Yin Xinxing (Huawei), Tobias Gondrom (Huawei), and the Connection ID task force team members: 

- Martin Thomson (Mozilla)
- Christian Huitema (Private Octopus Inc.)
- Jana Iyengar (Google)
- Daniel Kahn Gillmor (ACLU)
- Patrick McManus (Sole Proprietor)
- Ian Swett (Google)
- Mark Nottingham (Fastly)

Finally, we want to thank the IETF TLS working group chairs, Joseph Salowey and Sean Turner, for their patience, support and feedback. 

