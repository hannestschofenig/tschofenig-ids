---
title: Post Handshake Client and Server Authentication for Transport Layer Security (TLS) 1.3

abbrev: Post Handshake Mutual Authentication for TLS
docname: draft-tschofenig-tls-post-handshake-00
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

normative:
  RFC2119:
  I-D.ietf-tls-rfc8446bis:
  I-D.ietf-tls-tlsflags:
  RFC9147:
informative:

--- abstract

The Transport Layer Security (TLS) 1.3 specification offers a dedicated
extension to indicate support for post handshake client authentication. If a
client supports this extension, a server may request client authentication
at any time after the handshake has completed by sending a CertificateRequest
message.

The extension described in this document allows the client and the server to
request post handshake authentication. It thereby generalizes the post handshake
client authentication. The benefit of using this extension is that there is no
need to drop and re-establish a handshake. This feature can be used with
long-lived TLS connections where regular proof of possession of the long-term
secrets is required.

--- middle

#  Introduction

The Transport Layer Security (TLS) 1.3 specification offers a dedicated
extension to indicate support for post handshake client authentication. If a
client supports this extension, a server may request client authentication
at any time after the handshake has completed by sending a CertificateRequest
message.

The extension described in this document allows the client and the server to
request post handshake authentication. It thereby generalizes the post handshake
client authentication. The benefit of using this extension is that there is no
need to drop and re-establish a handshake. This feature can be used with
long-lived TLS connections where regular proof of possession of the long-term
secrets is required.

Functionality-wise this specification re-introduces features already present
in previous versions of TLS when re-negotiation was used.

This specification is applicable to both TLS 1.3 {{I-D.ietf-tls-rfc8446bis}} and
DTLS 1.3 {{RFC9147}}. Throughout the specification we do not distinguish between
these two protocols unless necessary for better understanding.

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

# Extensions

Client and servers use the TLS flags extension {{I-D.ietf-tls-tlsflags}}
to indicate support for the functionality defined in this document. We
call this the "post_handshake_auth_mutual" extension and the corresponding
flag is called "Post_Handshake_Auth_Mutual" flag.

The "Post_Handshake_Auth_Mutual" flag proposed by the client in the ClientHello
(CH) MUST be acknowledged in the EncryptedExtensions (EE), if the
server also supports the functionality defined in this document and
is configured to use it.

If the "Post_Handshake_Auth_Mutual" flag is not set, servers ignore the
functionality specified in this document and may, if supported, rely only
on the post handshake client authentication extension instead.

Clients may attempt to negotiate post handshake client authentication
and post handshake mutual authentication to offer servers the option
for a fall-back to post handshake client authentication only.

The functionality in this specification MUST only be used when mutual
authentication is performed during the initial handshake.

# Post-Handshake Mutual Authentication

Assuming support for the extension has been negotiated successfully,
a server MAY request client authentication at any time after the
handshake has completed by sending a CertificateRequest message. 
The client MUST respond with the appropriate Authentication messages.
If the client chooses to authenticate, it MUST send Certificate,
CertificateVerify, and Finished.  If it declines, it MUST send a
Certificate message containing no certificates followed by Finished.
All of the client's messages for a given response MUST appear
consecutively on the wire with no intervening messages of other types.

A client MAY request server authentication at any time after the
handshake has completed by sending a CertificateRequest message.
The server MUST respond with the appropriate Authentication messages.
If the server chooses to authenticate, it MUST send Certificate,
CertificateVerify, and Finished.  If it declines, it MUST send a
Certificate message containing no certificates followed by Finished.
All of the servers's messages for a given response MUST appear
consecutively on the wire with no intervening messages of other types.

A client or a server that receives a CertificateRequest message
without having sent the "post_handshake_auth_mutual" extension MUST
send an "unexpected_message" fatal alert.

Note: Because client authentication could involve prompting the user,
servers MUST be prepared for some delay, including receiving an
arbitrary number of other messages between sending the
CertificateRequest and receiving a response.  In addition, clients
which receive multiple CertificateRequests in close succession MAY
respond to them in a different order than they were received (the
certificate_request_context value allows the server to disambiguate
the responses).

# Example

{{fig-post-handshake}} shows an example where the client and
the server are mutually authenticated during the initial handshake.

The server then asks for the client to re-authenticate by issuing
a CertificateRequest message. Some point later the client
challenges the server to re-authenticate.

During post handshake authentication the client and the server
need to demonstrate possession of their private keys again.

~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share
     | + signature_algorithms
     v + post_handshake_auth_mutual   -------->
                                                  ServerHello  ^ Key
                                                  + key_share  | Exch
                                                               v
                                        {EncryptedExtensions   ^ Server
                                + post_handshake_auth_mutual}  | Params
                                         {CertificateRequest}  v
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]


         /-------------------------------------------\
        |              Some time later ...            |
         \-------------------------------------------/


                               <--------[CertificateRequest]
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->


         /-------------------------------------------\
        |              Some time later ...            |
         \-------------------------------------------/


       [CertificateRequest]    -------->
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v

       [Application Data]      <------->  [Application Data]
~~~
{: #fig-post-handshake title="Post Handshake Authentication Exchange."}

#  Security Considerations

The extension described in this specification covers a use case where
the TLS communication is long lived and interruption of this
established communication security channel is not desireable. Examples
of such use cases include industrial IoT environments and telecommunication
infrastructure. In many cases, IPsec has been used in the past
in those environments and is replaced by TLS or DTLS.

This document does not introduce renegotiation since security algorithms,
and keys are not re-negotiated. Instead, the security algorithms
and keys established by the initial handshake are re-used throughout the
lifetime of the communication interaction.

# IANA Considerations

IANA is requested to add the following value to the
"TLS Flags" extension defined in {{I-D.ietf-tls-tlsflags}}

*  Value: TBD

*  Flag Name: post_handshake_auth_mutual

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
