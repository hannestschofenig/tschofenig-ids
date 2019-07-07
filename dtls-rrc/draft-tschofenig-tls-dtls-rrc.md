---
title: Return Routability Check for DTLS 1.2 and DTLS 1.3
abbrev: DTLS Return Routability Check (RRC)
docname: draft-tschofenig-tls-dtls-rrc-latest
category: std
updates: 6347

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
       email: ekr@rtfm.com

 -
       ins: T. Fossati
       name: Thomas Fossati
       organization: Arm Limited
       email: thomas.fossati@arm.com

 -
       ins: H. Tschofenig
       name: Hannes Tschofenig
       organization: Arm Limited
       role: editor
       email: hannes.tschofenig@arm.com


normative:
  RFC2119:
  RFC5246:
  RFC6347:
  RFC8446:
  I-D.ietf-tls-dtls13:
  I-D.ietf-tls-dtls-connection-id:

informative:

--- abstract

This document specifies a return routability check for use in context of the Connection ID (CID) construct for the Datagram Transport Layer Security (DTLS) protocol versions 1.2 and 1.3.

--- middle


#  Introduction

In "classical" DTLS, selecting a security context of an incoming DTLS record
is accomplished with the help of the 5-tuple, i.e. source IP address, source port, transport protocol, destination IP address, and destination port. Changes to this 5 tuple can happen for a varity reasons over the lifetime of the DTLS session. In the IoT content NAT rebinding is a common reason with sleepy devices. Other examples include end host mobility and multi-homing. Without CID, if the source IP address and/or source port changes during the lifetime of an ongoing DTLS session then the receiver will be unable to locate the correct security context. As a result, the DTLS handshake has to be re-run. 

A CID is an identifier carried in the record layer header of a DTLS datagram that gives the
receiver additional information for selecting the appropriate security context. The CID mechanism has been specified in {{I-D.ietf-tls-dtls-connection-id}} for DTLS 1.2 and in {{I-D.ietf-tls-dtls13}} for DTLS 1.3. 

An on-path adversary could intercept and modify the source IP address (and the source port). Even if receiver checks the authenticity and freshness of the packet, the recipient is fooled into changing the  CID-to-IP/port association. This attack is possible because the network and transport layer identifiers, such as source IP address and source port numbers, are not integrity protected and authenticated by the DTLS record layer. 

This attack makes strong assumptions on the attacker's abilities, and moreover it only misleads the peer until the next message gets through un-intercepted.

It is possible to mitigate this attack using various ways. 

A return routability check (RRC) is performed by the receiving peer before
the CID-to-IP address/port is updated in that peer's session state database. This is done in order to provide a certain degree of confidence to the receiving peer that the sending peer is reachable at the indicated address and port.

Without such a return routability check, an adversary can redirect traffic towards a third party or a black hole.

While such a return routability check can be performed at the application layer it is advantageous to offer this functionality at the DTLS layer, as a generic service. 

This document specifies a new message to perform this return routability check. 

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

This document assumes familiarity with the CID solutions defined for DTLS 1.2 {{I-D.ietf-tls-dtls-connection-id}} and for DTLS 1.3 {{I-D.ietf-tls-dtls13}}.

# Application Layer Return Routability Check

When a record with CID is received that has the source address of the enclosing
UDP datagram different from the one previously associated with that CID, the
receiver MUST NOT update its view of the peer's IP address and port number with the source
specified in the UDP datagram before cryptographically validating the enclosed
record(s).  This is to ensure that a man-on-the-middle attacker that sends a
datagram with a different source address/port on an existing CID session does not
successfully manage to re-route any return traffic.

Furthermore, when using CID, anti-replay protection MUST be enabled. This is to ensure that a
man-on-the-middle attacker sending a previously captured record with a
modified source IP address and port will not be able to successfully pass the above check
(since the datagram is very likely discarded on receipt -- if it falls outside the replay window).

The two countermeasures cannot complete stop a man-in-the-middle attacker who performs a DoS on the sender or uses the receiver as as backscatter source for a DDoS attack. For a more generic protection,  a return routability check is needed. 

It is RECOMMENDED that implementations of the CID functionaliy described in {{I-D.ietf-tls-dtls-connection-id}} and in {{I-D.ietf-tls-dtls13}} added peer address update events to their APIs. Applications can then use these events as
triggers to perform an application layer return routability check, for
example one that is based on successful exchange of minimal amount of ping-pong
traffic with the peer.


# The Return Routability Check Message

~~~~
      enum {
          invalid(0),
          change_cipher_spec(20),
          alert(21),
          handshake(22),
          application_data(23),
          heartbeat(24),  /* RFC 6520 */
          return_routability_check(TBD), /* NEW */
          (255)
      } ContentType;
~~~~

The newly introduced return_routability_check message contains a cookie. The peer triggering the return routability check places the cookie in the message and the recipient echos it back. The semantic of the cookie is similar to the cookie used in the HelloRetryRequest message defined in TLS 1.3. 

~~~~
      struct {
          opaque cookie<1..2^16-1>;
      } Cookie;
      
      struct {
          Cookie cookie;
      } return_routability_check;
~~~~


# RRC Example

The example shown in {{fig-example}} illustrates a client and a server 
exchanging application playloads protected by DTLS with the unilaterally 
used CIDs. At some point in the communication interaction the IP addresses
used by the client changes and, thanks to the connection id usage, no new
DTLS handshake is necessary. However, the server wants to test the reachability 
of the client at his new IP address first before sending any data to the 
indicated IP address. 
 
~~~~
   Client                                             Server
   ------                                             ------

   Application Data            ========>
   <CID=100>
   Src-IP=A
   Dst-IP=Z
                               <========        Application Data
                                                    Src-IP=Z
                                                    Dst-IP=A
                               

                           <<------------->>
                           <<   Some      >>
                           <<   Time      >>
                           <<   Later     >> 
                           <<------------->>

                           
   Application Data            ========>
   <CID=100>
   Src-IP=B
   Dst-IP=Z

                                          <<< Unverified IP 
                                              Address B >>

                               <--------  Return Routability Check
                                                 (cookie)
                                                 Src-IP=Z
                                                 Dst-IP=B
                                                 
   Return Routability Check    -------->
   (cookie)
   Src-IP=B
   Dst-IP=Z

                                          <<< IP Address B 
                                              Verified >>

   
                               <========        Application Data
                                                    Src-IP=Z
                                                    Dst-IP=B
~~~~
{: #fig-example title='Return Routability Example'}


# Security and Privacy Considerations {#sec-cons}

   As all the datagrams in DTLS are authenticated, integrity and confidentiality protected there is no
   risk that an attacker undetectedly modifies the contents of those
   packets.  The IP addresses in the IP header and the port numbers of the transport layer are, however, not
   authenticated. With the introduction of the connection id, care must be 
   taken to test reachablity of a peer at a given IP addres and port. 

   Note that the return routability checks do not protect against third-party
   flooding if the attacker is along the path, as the attacker can
   forward the return routability checks to the real peer (even if those
   datagrams are cryptographically authenticated).
      
#  IANA Considerations

IANA is requested to allocate an entry to the existing TLS "ContentType" registry, for the return_routability_check(TBD) defined in
this document.

#  Open Issues

- Should the return routability check use separate sequence numbers and replay windows?
- Should the heartbeat message be re-used instead of the proposed new message exchange? 

--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

  - Initial version

# Working Group Information

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

The discussion list for the IETF TLS working group is located at the e-mail
address <tls@ietf.org>. Information on the group and information on how to
subscribe to the list is at <https://www1.ietf.org/mailman/listinfo/tls>

Archives of the list can be found at:
<https://www.ietf.org/mail-archive/web/tls/current/index.html>

# Acknowledgements

We would like to thank Achim Kraus, Hanno Becker and Manuel Pegourie-Gonnard for their input to this document. 
