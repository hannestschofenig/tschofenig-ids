---
title: Using CBOR Web Tokens (CWTs) in Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS)
abbrev: CWTs in TLS/DTLS
docname: draft-tschofenig-tls-cwt-latest
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
       ins: H. Tschofenig
       name: Hannes Tschofenig
       organization: Arm Limited
       role: editor
       email: hannes.tschofenig@arm.com

 -
       ins: M. Brossard
       name: Mathias Brossard
       organization: Arm Limited
       email: Mathias.Brossard@arm.com

normative:
  RFC2119:
  I-D.ietf-tls-dtls13:
  I-D.ietf-ace-cwt-proof-of-possession:
  RFC8446:
  RFC7250:
  RFC8152:
  RFC8392:
informative:
  RFC7519: 
  RFC7925:
  RFC7525:
  RFC6125:
  
--- abstract

The TLS protocol supports different credentials, including pre-shared keys, raw public keys, and 
X.509 certificates. For use with public key cryptography developers have to decide between raw public 
keys, which require out-of-band agreement and full-fletched X.509 certificates. For devices where 
the reduction of code size is important it is desirable to minimize the use of X.509-related libraries. 
With the CBOR Web Token (CWT) a structure has been defined that allows CBOR-encoded claims to be 
protected with CBOR Object Signing and Encryption (COSE). 

This document registers a new value to the "TLS Certificate Types" subregistry to allow TLS and DTLS
to use CWTs. Conceptually, CWTs can be seen as a certificate format (when with public key cryptography) 
or a Kerberos ticket (when used with symmetric key cryptography). 

--- middle


#  Introduction

The CBOR Web Token (CWT) {{RFC8392}} was defined as the CBOR-based version of the JSON Web Token (JWT) {{RFC7519}}. 
JWT is used extensibly on Web application and for use with Internet of Things environments the believe is that 
a more lightweight encoding, namely CBOR, is needed. CWTs, like JWTs, contain claims and those claims are 
protected against modifications using COSE {{RFC8152}}. CWTs are flexible with regard to the use of 
cryptography and hence CWTs may be protected using a keyed message digest, or a digital signature. One of the 
claims allows keys to be included, as described in {{I-D.ietf-ace-cwt-proof-of-possession}}. This specification
makes use of these proof-of-possession claims in CWTs. 

Fundamentially, there are two types of keys that can be used with CWTs: 

* Asymmetric keys: In this case a CWT contains a COSE_Key {{RFC8152}} representing
  an asymmetric public key. To protect the CWT against modifications the CWT also needs to be digitally signed. 
  
* Symmetric keys: In this case a CWT contains a Encrypted_COSE_Key {{RFC8152}} representing a symmetric key 
  encrypted to a key known to the recipient using COSE_Encrypt or COSE_Encrypt0. Again, to protect the CWT
  against modifications a keyed message digest is used. 
  
The CWT also allows mixing symmetric and asymmetric crypto although this is less likely to be used in practice.   

Exchanging CWTs in the TLS / DTLS handshake offers an alternative to the use of raw 
public keys and X.509 certificates. Compared to raw public keys, CWTs allow more information to be included via 
the use of claims. Compared to X.509 certificates CBOR offers an alternative encoding format, which may also 
be used by the application layer thereby potentially reducing the overall code size requirements. 

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

# The CWT Certificate Type

This document defines a new value to the "TLS Certificate Types" subregistry and 
the value is defined as follows. 

~~~~

     /* Managed by IANA */
      enum {
          X509(0),
          RawPublicKey(2),
          CWT(TBD),
          (255)
      } CertificateType;

      struct {
          select (certificate_type) {

              /* CWT "certificate type" defined in this document.*/
               case CWT:
               opaque cwt_data<1..2^24-1>;

               /* RawPublicKey defined in RFC 7250*/
              case RawPublicKey:
              opaque ASN.1_subjectPublicKeyInfo<1..2^24-1>;

              /* X.509 certificate defined in RFC 5246*/
              case X.509:
              opaque cert_data<1..2^24-1>;

               };

             Extension extensions<0..2^16-1>;
      } CertificateEntry;
~~~~

# Representation and Verification the Identity of Application Services
 
RFC 6125 {{RFC6125}} provides guidance for matching identifiers used in X.509 certificates 
against a reference identifier, i.e. an identifier constructed from a source
domain and optionally an application service type. Different types of identifiers have been 
defined over time, such as CN-IDs,  DNS-IDs, SRV-IDs, and URI-IDs, and they may be carried 
in different fields inside the X.509 certificate, such as in the Common Name or in the 
subjectAltName extension. 

For CWTs issued to servers the following rule applies: To claim conformance with this 
specification an implementation MUST populate the Subject claim 
with the value of the Server Name Indication (SNI) extension. The Subject claim is of type 
StringOrURI. If it is string an equality match is used between the Subject claim value and the SNI.
If the value contains a URI then the URI schema must be matched against the service being requested 
and the remaining part of the URI is matched against the SNI in an equality match (since the SNI 
only defines Hostname types).

For CWTs issued to clients the application service interacting with the TLS/DTLS stack on the 
server side is responsible for authenticating the client. No specific rules apply but the 
Subject and the Audience claims are likely to be good candidates for authorization policy checks. 

Note: Verification of the Not Before and the Expiration Time claims 
MUST be performed to determine the validity of the received CWT.  

#  Security and Privacy Considerations {#sec-cons}

The security and privacy characteristics of this extension are best described
in relationship to certificates (when asymmetric keys  are used) and to Kerberos 
tickets (when symmetric keys are used) since the main difference is in the 
encoding. 

When creating proof-of-possession keys the recommendations for state-of-the-art 
key sizes and algorithms have to be followed. For TLS/DTLS those algorithm 
recommendations can be found in {{RFC7925}} and {{RFC7525}}.

CWTs without proof-of-possession keys MUST NOT be used. 

When CWTs are used with TLS 1.3 {{RFC8446}} and DTLS 1.3 {{I-D.ietf-tls-dtls13}}
additional privacy properties are provided since most handshake messages are encrypted. 


#  IANA Considerations

IANA is requested to add a new value to the "TLS Certificate Types" subregistry 
for CWTs. 

--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

  - Initial version

# Working Group Information

The discussion list for the IETF TLS working group is located at the e-mail
address <tls@ietf.org>. Information on the group and information on how to
subscribe to the list is at <https://www1.ietf.org/mailman/listinfo/tls>

Archives of the list can be found at:
<https://www.ietf.org/mail-archive/web/tls/current/index.html>

