---
title: Using Attestation in Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS)
abbrev: Attestation in TLS/DTLS
docname: draft-fossati-tls-attestation-02
category: std

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
       email: hannes.tschofenig@arm.com

 -
       ins: T. Fossati
       name: Thomas Fossati
       organization: Arm Limited
       email: Thomas.Fossati@arm.com

 -
       ins: P. Howard
       name: Paul Howard
       organization: Arm Limited
       email: Paul.Howard@arm.com

 -
       ins: I. Mihalcea
       name: Ionut Mihalcea
       organization: Arm Limited
       email: Ionut.Mihalcea@arm.com

 -
       ins: Y. Deshpande
       name: Yogesh Deshpande
       organization: Arm Limited
       email: Yogesh.Deshpande@arm.com


normative:
  RFC2119:
  RFC8446:
  I-D.ftbs-rats-msg-wrap:
  kat:
    target: draft-fossati-rats-kat
    title: Key Attestation Token
    author:
      -
        org: 
    date: October 2022  
informative:
  I-D.ietf-rats-eat:
  RFC5246:
  TPM1.2:
    target: https://trustedcomputinggroup.org/resource/tpm-main-specification/
    title: TPM Main Specification Level 2 Version 1.2, Revision 116
    author:
      -
        org: Trusted Computing Group
    date: March 2011
  TPM2.0:
    target: https://trustedcomputinggroup.org/resource/tpm-library-specification/
    title: Trusted Platform Module Library Specification, Family "2.0", Level 00, Revision 01.59
    author:
      -
        org: Trusted Computing Group
    date: November 2019
  RFC7250:
  I-D.ietf-rats-architecture:

--- abstract

Attestation is the process by which an entity produces evidence about itself
that another party can use to evaluate the trustworthiness of that entity.

In use cases that require the use of remote attestation, such as confidential computing
or device onboarding, an attester has to convey evidence or attestation results to 
a relying party. This information exchange may happen at different layers in the 
protocol stack. 

This specification provides a generic way of passing evidence and attestation results
in the TLS handshake. Functionality-wise this is accomplished with the help of key
attestation.

--- middle

#  Introduction

The Remote ATtestation ProcedureS (RATS) architecture defines two basic types 
of topological patterns to communicate between an attester, a relying party, and
a verifier, namely the background-check model and the passport model. These two 
models are fundamentally different and require a different treatment when 
incorporated into the TLS handshake. For better readability to use different 
extensions for these two models.

The two models can be summarized as follows:

- In the background check model, the attester conveys evidence to the relying party,
  which then forwards the evidence to the verifier for appraisal; the verifier 
  computes the attestation result and sends it back to the relying party.
- In the passport model, the attester transmits evidence to the  verifier 
  directly and receives attestation results, which are then relayed to the
  relying party. This specification supports both patterns.

Several formats for encoding evidence are available, such as 
- the Entity Attestation Token (EAT) {{I-D.ietf-rats-eat}}, 
- the Trusted Platform Modules (TPMs) {{TPM1.2}} {{TPM2.0}},
- the Android Key Attestation, and
- Apple Key Attestation. 

Like-wise, there are different encodings available for attestation results.
One such encoding, AR4SI {{?I-D.ietf-rats-ar4si}} is being standardized by the RATS 
working group.

This version of the specification defines how to support the background check model
in  the TLS handshake, such that the details about the attestation technology are
agnostic to the TLS handshake itself. Later versions of the specification will 
support the passport model as well. 

To give the peer information that the handshake signing key is properly secured, 
the associated evidence has to be verified by that peer.
Hence, attestation evidence about the security state of the signing key is needed, which
is typically associated with evidence about the overall platform state. The platform 
attestation service ensures that the key attestation service has not been tampered with.
The platform attestation service issues the Platform Attestation Token (PAT) and the
key attestation service issues the Key Attestation Token (KAT). The security of the 
protocol critically depends on the verifiable binding between these two logically separate
units of evidence.

This document does not define how different attestation technologies are encoded.
This has either already been done is done accomplished by companion specifications.

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

# Overview

The Remote Attestation Procedures (RATS) architecture {{I-D.ietf-rats-architecture}}
defines two types of interaction models for attestation, namely the passport model
and the background-check model. The subsections below explain the difference in their 
interactions.

To simplify the description in this section we focus on the use case where the 
client is the attester and the server is the relying party. Hence, only the
client_attestation_type extension is discussed. The verifier is not shown in 
the diagrams. The described mechanism allows the roles to be reversed.

As typical with new features in TLS, the client indicates support for the new 
extension in the ClientHello. The newly introduced extensions allow evidence
and attstation result formats to be indicated and enable the exchange of nonces.
Those nonces are used for guaranteeing freshness of the exchanged attestation payloads.

When the attestation extension is successfully negotiated, the content of the
Certificate message contains a payload that is encoded based on the wrapper defined 
in {{I-D.ftbs-rats-msg-wrap}}.

In TLS a client has to demonstrate possession of the private key via the CertificateVerify
message, when client-based authentication is requested. The attestation payload
must contain a key attestation token, which associates a private key with the
attestation information. More information about the key attestation token format can 
be found in {{kat}}.

The recipient of the Certificate and the CertificateVerify messages first extracts 
the attestation payload from the Certificate message and either relays it to the 
verifier (if evidence was received) or processes it locally (if attestation results
were received). Verification of the attestation payloads happens according to the
defined format.

# Use of Evidence with the Background Check Model

The background check model is described in Section 5.2 of 
{{I-D.ietf-rats-architecture}} and allows the following modes
of operation when used with TLS, namely

- TLS client is the attester, 
- TLS server is the attester, and
- TLS client and server mutually attest each other. 

We will show the message exchanges of the three cases in
sub-sections below. 

## TLS Client as Attester 

In this use case the TLS client, as the attester, is challenged by the TLS
server to provide evidence. The TLS client is the attester and the the TLS
server acts as a relying party. The TLS server needs to provide a nonce
in the EncryptedExtensions to the TLS client so that the attestation
service can feed the nonce into the generation of the evidence. The TLS 
server, when receiving the evidence, will have to contact the verifier 
(which is not shown in the diagram). 

An example of this flow can be found in device onboarding where the 
client initiates the communication with cloud infrastructure to 
get credentials, firmware and other configuration data provisioned
to the device. For the server to consider the device genuine it needs
to present evidence.

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + evidence_proposal
     | + key_share*
     | + signature_algorithms*
     v                         -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                                               v
                                        {EncryptedExtensions}  ^  Server
                                          + evidence_proposal  |  Params
                                                      (nonce)  |
                                         {CertificateRequest}  v  
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------  [Application Data*]
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
~~~~
{: #figure-background-check-model1 title="TLS Client Providing Evidence to TLS Server."}


## TLS Server as Attester

In this use case the TLS client challenges the TLS server to present evidence. 
The TLS server acts as an attester while the TLS client is the relying party. 
The TLS client, when receiving the evidence, will have to contact the verifier 
(which is not shown in the diagram).

An example of this flow can be found in confidential computing where 
a compute workload is only submitted to the server infrastructure 
once the client/user is ensured that the confidential computing platform is
genuine. 

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + evidence_request
     |   (nonce)
     | + key_share*
     | + signature_algorithms*
     v                         -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                                               v
                                        {EncryptedExtensions}  ^  Server
                                          + evidence_request   |  Params
                                                               |
                                         {CertificateRequest}  v  
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------  [Application Data*]
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
~~~~
{: #figure-background-check-model1 title="TLS Client Providing Evidence to TLS Server."}

# Evidence Extension (Background Check Model)

This document defines two new extensions, the evidence_request and 
the evidence_proposal, for use with the background check model. 

The EvidenceType structure encodes either a media type or as a
content format. The media type is a string-based identifier 
while the content format uses a number. The former is more 
flexible and does not necessarily require a registration 
through IANA while the latter is more efficient over-the-wire.

~~~~
   enum { NUMERIC(0), STRING(1) } encodingType;

   struct {
        encodingType type;
        select (encodingType) {
            case NUMERIC:
              uint16 content_format;
            case STRING:
               opaque media_type<0..2^16-1>;
        };
   } EvidenceType;
      
   struct {
           select(ClientOrServerExtension) {
               case client:
                 EvidenceType supported_evidence_types<1..2^8-1>;
                 opaque nonce<0..2^8-1>;
                 
               case server:
                 EvidenceType selected_evidence_type;
           }
   } evidenceRequestTypeExtension;

   struct {
           select(ClientOrServerExtension) {
               case client:
                 EvidenceType supported_evidence_types<1..2^8-1>;

               case server:
                 EvidenceType selected_evidence_type;
                 opaque nonce<0..2^8-1>;
           }
   } evidenceProposalTypeExtension;
~~~~
{: #figure-attestation-type title="TLS Structure for Evidence."}

The Certificate payload is used as a container, as shown in 
{{figure-certificate}}, and follows the model of {{RFC8446}}.

~~~~
      struct {
          select (certificate_type) {
              case RawPublicKey:
                /* From RFC 7250 ASN.1_subjectPublicKeyInfo */
                opaque ASN1_subjectPublicKeyInfo<1..2^24-1>;

                /* payload used to convey evidence */
              case attestation:
                opaque evidence<1..2^24-1>;
              
              case X509:
                opaque cert_data<1..2^24-1>;
          };
          Extension extensions<0..2^16-1>;
      } CertificateEntry;

      struct {
          opaque certificate_request_context<0..2^8-1>;
          CertificateEntry certificate_list<0..2^24-1>;
      } Certificate;
~~~~
{: #figure-certificate title="Certificate Message."}

The encoding of the payload that is conveyed by the evidence 
structure is defined in {{I-D.ftbs-rats-msg-wrap}}.

# TLS Client and Server Handshake Behavior {#behavior}

The high-level message exchange in {{figure-overview}} shows the
client_attestation_type and server_attestation_type extensions added
to the ClientHello and the EncryptedExtensions messages.

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share*
     | + signature_algorithms*
     | + psk_key_exchange_modes*
     | + pre_shared_key*
     | + client_attestation_type
     v + server_attestation_type
     -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                            + pre_shared_key*  v
                                        {EncryptedExtensions}  ^  Server
                                    + client_attestation_type  |
                                    + server_attestation_type                                        
                                        {CertificateRequest*}  v  Params
                                               {Certificate*}  ^
                                         {CertificateVerify*}  | Auth
                                                   {Finished}  v
                               <--------  [Application Data*]
     ^ {Certificate*}
Auth | {CertificateVerify*}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
~~~~
{: #figure-overview title="Attestation Message Overview."}

## Client Hello

   In order to indicate the support of attestation types, clients include
   the client_attestation_type and/or the server_attestation_type
   extensions in the ClientHello.

   The client_attestation_type extension in the ClientHello indicates
   the attestation types the client is able to provide to the server,
   when requested using a CertificateRequest message.

   The server_attestation_type extension in the ClientHello indicates
   the types of attestation types the client is able to process when 
   provided by the server in a subsequent Certificate payload.

   The client_attestation_type and server_attestation_type extensions
   sent in the ClientHello each carry a list of supported attestation
   types, sorted by client preference.  When the client supports only
   one attestation type, it is a list containing a single element.

   The TLS client MUST omit attestation types from the
   client_attestation_type extension in the ClientHello if it is not
   equipped with the corresponding attestation functionality, or if 
   it is not configured to use it with the given TLS
   server.  If the client has no attestation types to send in
   the ClientHello it MUST omit the client_attestation_type extension 
   in the ClientHello.

   The TLS client MUST omit attestation types from the
   server_attestation_type extension in the ClientHello if it is not
   equipped with the attestation verification functionality.  If the 
   client has no attestation types to send in the ClientHello it
   MUST omit the entire server_attestation_type extension from the
   ClientHello.

## Server Hello

   If the server receives a ClientHello that contains the
   client_attestation_type extension and/or the server_attestation_type
   extension, then three outcomes are possible:

   -  The server does not support the extension defined in this
       document.  In this case, the server returns the EncryptedExtensions
       without the extensions defined in this document.

   -  The server supports the extension defined in this document, but
       it does not have any attestation type in common with the client.
       Then, the server terminates the session with a fatal alert of
       type "unsupported_certificate".

   -  The server supports the extensions defined in this document and
       has at least one attestation type in common with the client.  In
       this case, the processing rules described below are followed.

   The client_attestation_type extension in the ClientHello indicates
   the attestation types the client is able to provide to the server,
   when requested using a certificate_request message.  If the TLS
   server wants to request a certificate from the client (via the
   certificate_request message), it MUST include the
   client_attestation_type extension in the EncryptedExtensions.  This
   client_attestation_type extension in the EncryptedExtensions then indicates
   the content the client is requested to provide in a
   subsequent Certificate payload.  The value conveyed in the
   client_attestation_type extension MUST be selected from one of the
   values provided in the client_attestation_type extension sent in the
   client hello.  The server MUST also include a certificate_request
   payload in the EncryptedExtensions message.

   If the server does not send a certificate_request payload (for
   example, because client authentication happens at the application
   layer or no client authentication is required) or none of the
   attestation types supported by the client (as indicated in the
   client_attestation_type extension in the ClientHello) match the
   server-supported attestation types, then the client_attestation_type
   payload in the ServerHello MUST be omitted.

   The server_attestation_type extension in the ClientHello indicates
   the types of attestation types the client is able to process when provided
   by the server in a subsequent Certificate message. With the
   server_attestation_type extension in the EncryptedExtensions, the TLS server
   indicates the attestation type carried in the Certificate payload.
   Note that only a single value is permitted in the 
   server_attestation_type extension when carried in the EncryptedExtensions
   message.

# Background-Check Model Examples

## Cloud Confidential Computing

{::include diagrams/background-check-tls-handshake.txt}

## IoT Device Onboarding

TBD.

# Security Considerations {#sec-cons}

TBD.

# IANA Considerations

IANA is asked to allocate two new TLS extensions, client_attestation_type
and server_attestation_type, from the "TLS ExtensionType Values"
subregistry defined in {{RFC5246}}.  These extensions are used in both
the client hello message and the server hello message. The
values carried in these extensions are taken from TBD.

--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

## draft-fossati-tls-attestation-02

- Added more diagrams
- Updated introduction
- Moved content to related drafts.
    
## draft-fossati-tls-attestation-01

- Added details about TPM attestation
    
## draft-fossati-tls-attestation-00

- Initial version

# Working Group Information

The discussion list for the IETF TLS working group is located at the e-mail
address <tls@ietf.org>. Information on the group and information on how to
subscribe to the list is at <https://www1.ietf.org/mailman/listinfo/tls>

Archives of the list can be found at:
<https://www.ietf.org/mail-archive/web/tls/current/index.html>

