---
title: The Datagram Transport Layer Security (DTLS) Connection Identifier for DTLS 1.3
abbrev: DTLS 1.3 Connection ID
docname: draft-ietf-tls-dtls13-cid-latest
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
       organization: Arm Limited
       role: editor
       email: hannes.tschofenig@arm.com
 -
       ins: T. Fossati
       name: Thomas Fossati
       organization: Nokia
       email: thomas.fossati@nokia.com

 -
       ins: T. Gondrom
       name: Tobias Gondrom
       organization: Huawei
       email: tobias.gondrom@gondrom.org


normative:
  RFC2119:
  I-D.ietf-tls-dtls13:
informative:
  RFC6973:
  
--- abstract

This document specifies the "Connection ID" concept for the Datagram Transport Layer Security
(DTLS) 1.3 protocol. A companion document specifies the concept for DTLS 1.2. 

A Connection ID is an identifier carried in the record layer header that gives the
recipient additional information for selecting the appropriate security association.
In "classical" DTLS, selecting a security association of an incoming DTLS record
is accomplished with the help of the 5-tuple. If the source IP address and/or
source port changes during the lifetime of an ongoing DTLS session then the
receiver will be unable to locate the correct security context.

--- middle


#  Introduction

The Datagram Transport Layer Security (DTLS) protocol was designed for securing
connection-less transports, like UDP. In the current version of DTLS, the IP address 
and port of the peer is used to identify the DTLS association. 

This version of the document extends the functionality 
defined in {{I-D.ietf-tls-dtls-connection-id}} in the following ways: 
 
* It is designed for use with DTLS 1.3 and thereby benefits from its functionality. 

* Connection ID values can be updated using a Post-Handshake message. This allows 
obtaining new connection IDs in a confidential way. 

* Improved privacy protection because the DTLS client and server can change connection 
IDs at any time, assuming they have spare IDs, which makes correlation of packets 
more difficult. 

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The reader is assumed to be familiar with DTLS 1.3 {{RFC6347}}.

# The "connection_id" Extension

This document re-uses the connection_id extension defined in {{I-D.ietf-tls-dtls-connection-id}}, which
is used in ClientHello and ServerHello messages.

# Post-Handshake Messages

If the client and server have negotiated the "connection_id" extension,
either side can send a new connection ID which it wishes the other side to use
in a NewConnectionId message:

~~~
   enum {
       cid_immediate(0), cid_spare(1), (255)
   } ConnectionIdUsage;

   struct {
       opaque cid<0..2^8-1>;
       ConnectionIdUsage usage;
   } NewConnectionId;
~~~

cid
: Indicates the CID which the sender wishes the peer to use.

usage
: Indicates whether the new CID should be used immediately or is a spare.
If usage is set to "cid_immediate", then the new CID MUST be used immediately
for all future records. If it is set to "cid_spare", then either CID MAY
be used.
{:br}

If the client and server have negotiated the "connection_id" extension,
either side can request a new CID using the RequestConnectionId message.

~~~
   struct {
   } RequestConnectionId;
~~~

Endpoints SHOULD respond to RequestConnectionId by sending a NewConnectionId
with usage "cid_spare" as soon as possible. Note that an endpoint MAY ignore
requests, which it considers excessive (though they MUST be ACKed as usual).

# Record Layer Header Extensions

{{dtls-record}} illustrates the DTLS 1.3 record format with the CID
field included.

~~~~
  struct {
     ContentType type;
     ProtocolVersion version;
	 opaque cid_hdr[variable]; 
     select (CipherSpec.cipher_type) {
        case block:  GenericBlockCipher;
        case aead:   GenericAEADCipher;
     } fragment;
  } DTLSCiphertext;
~~~~
{: #dtls-record title="DTLS 1.3 Record Format with Connection ID"}

The cid_hdr is field of variable length, as shown in {{cid_hdr}}. 

~~~~
  0 1 2 3 4 5 6 7
 +-+-+-+-+-+-+-+-+
 |0|0|1|C|L|X|X|X|
 +-+-+-+-+-+-+-+-+
 |E|E| 14 bit    |   Legend:
 +-+-+           |
 |Sequence Number|   C - CID present
 +-+-+-+-+-+-+-+-+   L - Length present
 | 16 bit Length |   E - Epoch
 | (if present)  |   X - Reserved
 +-+-+-+-+-+-+-+-+
 | Connection ID |
 | (if any,      |
 /  length as    /
 |  negotiated)  |
 +-+-+-+-+-+-+-+-+
~~~~
{: #cid_hdr title="DTLS 1.3 CID-extended Header"}
 
Besides the "cid_hr" field, all other fields are defined in the DTLS 1.3 
specification.

{{hdr_examples}} illustrates different record layer header types. 

~~~~
   0 1 2 3 4 5 6 7        0 1 2 3 4 5 6 7
  +-+-+-+-+-+-+-+-+      +-+-+-+-+-+-+-+-+
  | Content Type  |      | Content Type  |
  +-+-+-+-+-+-+-+-+      +-+-+-+-+-+-+-+-+
  |   16 bit      |      |   16 bit      |
  |   Version     |      |   Version     |
  +-+-+-+-+-+-+-+-+      +-+-+-+-+-+-+-+-+
  |0|0|1|C|L|X|X|X|      |0|0|1|0|0|X|X|X|
  +-+-+-+-+-+-+-+-+      +-+-+-+-+-+-+-+-+
  |E|E| 14 bit    |      |E|E| 14 bit    |
  +-+-+           |      +-+-+           |
  |Sequence Number|      |Sequence Number|
  +-+-+-+-+-+-+-+-+      +-+-+-+-+-+-+-+-+
  |   16 bit      |      |               |
  |   Length      |      |               |
  +-+-+-+-+-+-+-+-+      /   Fragment    /
  |               |      |               |
  |               |      +-+-+-+-+-+-+-+-+
  / Connection ID /
  |               |
  +-+-+-+-+-+-+-+-+
  |               |
  |               |
  /   Fragment    /
  |               |
  +-+-+-+-+-+-+-+-+

   Full-Featured           Minimalistic
      Header                 Header
~~~~
{: #hdr_examples title="Header Examples"}

# Examples

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
                                          (connection_id=100)
                                          EncryptedExtensions
                                                      (cid=5)
                                                  Certificate
                                                      (cid=5)
                                            CertificateVerify
                                                      (cid=5)
                                                     Finished
                                                      (cid=5)

Certificate                -------->
(cid=100)
CertificateVerify
(cid=100)
Finished
(cid=100)
                           <--------                      Ack
                                                      (cid=5)

Application Data           ========>
(cid=100)
                           <========         Application Data
                                                      (cid=5)
~~~~
{: #dtls-example title="Example DTLS 1.3 Exchange with Connection IDs"}

#  Security and Privacy Considerations {#sec-cons}

The security and privacy properties of the connection ID for DTLS 1.3 builds 
on top of what is described in {{I-D.ietf-tls-dtls-connection-id}}. There are, 
however, several improvements. 

The use of the Post-Handshake message allows the client and the server 
to update their connection IDs and those values are exchanged with confidentiality 
protection. 

With multi-homing, an adversary is able to correlate the communication
interaction over the two paths, which adds further privacy concerns. In order
to prevent this, implementations SHOULD attempt to use fresh connection IDs
whenever they change local addresses or ports (though this is not always
possible to detect). The RequestConnectionId message can be used
to ask for new IDs in order to ensure that you have a pool of suitable IDs.

Switching connection ID based on certain events, or even regularly, helps against 
tracking by onpath adversaries but the sequence numbers can still allow
linkability. [[OPEN ISSUE: We need to update the document to offer sequence number encryption. ]]

Since the DTLS 1.3 exchange encrypts handshake messages much earlier than in previous 
DTLS versions information identifying the DTLS client, such as the client certificate, less 
information is available to an on-path adversary. 

#  IANA Considerations

   IANA is requested to allocate one value in the "TLS Handshake Type"
   registry, defined in {{RFC5246}}, for request_connection_id (TBD), 
   as defined in this document.

--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

draft-ietf-tls-dtls13-cid-00

  - Initial version of the DTLS CID 1.3
    specification.
	
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
* Nikos Mavrogiannopoulos
  RedHat
  nmav@redhat.com
~~~

Additionally, we would like to thank Yin Xinxing (Huawei), and the Connection ID task force team members:

- Martin Thomson (Mozilla)
- Christian Huitema (Private Octopus Inc.)
- Jana Iyengar (Google)
- Daniel Kahn Gillmor (ACLU)
- Patrick McManus (Sole Proprietor)
- Ian Swett (Google)
- Mark Nottingham (Fastly)

Finally, we want to thank the IETF TLS working group chairs, Joseph Salowey and Sean Turner, for their patience, support and feedback.

