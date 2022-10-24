---
title: Using Attestation in Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS)
abbrev: Attestation in TLS/DTLS
docname: draft-fossati-tls-attestation-02
category: std

ipr: trust200902
area: Security
workgroup: TLS
keyword: [ attestation, RATS, TLS ]

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
  I-D.bft-rats-kat:
informative:
  I-D.ietf-rats-eat:
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
  I-D.ietf-rats-architecture:
  TLS-Ext-Registry: IANA.tls-extensiontype-values
  TLS-Param-Registry: IANA.tls-parameters

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
and the background check model. The subsections below explain the difference in their 
interactions.

As typical with new features in TLS, the client indicates support for the new 
extension in the ClientHello. The newly introduced extensions allow evidence
and nonces to be exchanged. The nonces are used for guaranteeing freshness of
the exchanged evidence.

When the evidence extension is successfully negotiated, the content of the
Certificate message contains a payload that is encoded based on the wrapper defined 
in {{I-D.ftbs-rats-msg-wrap}}.

In TLS a client has to demonstrate possession of the private key via the CertificateVerify
message, when client-based authentication is requested. The attestation payload
must contain a key attestation token, which associates a private key with the
attestation information. An example of a key attestation token format utilizing 
the EAT-format can be found in {{I-D.bft-rats-kat}}.

The recipient extracts evidence from the Certificate message and relays it to the 
verifier to obtain attestation results. Subsequently, the attested key is used
to verify the CertificateVerify message.

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
{: #figure-background-check-model2 title="TLS Client Providing Evidence to TLS Server."}

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

The encoding of the evidence structure is defined in
{{I-D.ftbs-rats-msg-wrap}}.

# TLS Client and Server Handshake Behavior {#behavior}

The high-level message exchange in {{figure-overview}} shows the
evidence_proposal and evidence_request extensions added
to the ClientHello and the EncryptedExtensions messages.

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share*
     | + signature_algorithms*
     | + psk_key_exchange_modes*
     | + pre_shared_key*
     | + evidence_proposal
     v + evidence_request
     -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                            + pre_shared_key*  v
                                        {EncryptedExtensions}  ^  Server
                                          + evidence_proposal  |
                                           + evidence_request  |                                     
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

To indicate the support for passing evidence in TLS following the 
background check model, clients include the evidence_proposal 
and/or the evidence_request extensions in the ClientHello.

The evidence_proposal extension in the ClientHello indicates
the evidence types the client is able to provide to the server,
when requested using a CertificateRequest message.

The evidence_request extension in the ClientHello indicates
the types of evidence types the client challenges the server to 
provide in a subsequent Certificate payload.

The evidence_proposal and evidence_request extensions sent in
the ClientHello each carry a list of supported evidence types,
sorted by preference.  When the client supports only one evidence
type, it is a list containing a single element.

The client MUST omit evidence types from the evidence_proposal 
extension in the ClientHello if it cannot respond to a request
from the server to present a proposed evidence type, or if 
the cient is not configured to use the proposed evidence type 
with the given server.  If the client has no evidenence types 
to send in the ClientHello it MUST omit the evidence_proposal
extension in the ClientHello.

The client MUST omit evidence types from the evidence_request
extension in the ClientHello if it is not able to pass the 
indicated verification type to a verifier.  If the client does 
not act as a relying party with regards to evidence processing
(as defined in the RATS architecture) then the client MUST 
omit the evidence_request extension from the ClientHello.

## Server Hello

If the server receives a ClientHello that contains the
evidence_proposal extension and/or the evidence_request
extension, then three outcomes are possible:

-  The server does not support the extension defined in this
   document.  In this case, the server returns the EncryptedExtensions
   without the extensions defined in this document.

-  The server supports the extension defined in this document, but
   it does not have any evidence type in common with the client.
   Then, the server terminates the session with a fatal alert of
   type "unsupported_evidence".

-  The server supports the extensions defined in this document and
   has at least one evidence type in common with the client.  In
   this case, the processing rules described below are followed.

The evidence_proposal extension in the ClientHello indicates
the evidence types the client is able to provide to the server,
when challenged using a certificate_request message.  If the
server wants to request evidence from the client, it MUST include the
client_attestation_type extension in the EncryptedExtensions. This
evidence_proposal extension in the EncryptedExtensions then indicates
what evidence format the client is requested to provide in a
subsequent Certificate message.  The value conveyed in the
evidence_proposal extension by the server MUST be selected from one of the
values provided in the evidence_proposal extension sent in the
ClientHello.  The server MUST also send a certificate_request
message.

If the server does not send a certificate_request message or none 
of the evidence types supported by the client (as indicated in the
evidence_proposal extension in the ClientHello) match the
server-supported evidence types, then the evidence_proposal
extension in the ServerHello MUST be omitted.

The evidence_request extension in the ClientHello indicates what
types of evidence the client can challenge the server to return. 
in a subsequent Certificate message. With the evidence_request 
extension in the EncryptedExtensions, the server indicates the 
evidence type carried in the Certificate message sent by the server.
The evidence type in the evidence_request extension MUST contain 
a single value selected from the evidence_request extension in 
the ClientHello.

# Background-Check Model Examples

## Cloud Confidential Computing

In this example, a confidential workload is executed on computational
resources hosted at a cloud service provider.  This is a typical
scenario for secure, privacy-preserving multiparty computation,
including anti-money laundering, drug development in healthcare, contact
tracing in pandemic times, etc.

In such scenarios, the users (e.g., the party providing the data input
for the computation, the consumer of the computed results, the party
providing a proprietary ML model used in the computation) have two
goals:

* Identifying the workload they are interacting with,
* Making sure that the platform on which the workload executes is a
  Trusted Execution Environment (TEE) with the expected features.

A convenient arrangement is to verify that the two requirements are met
at the same time that the secure channel is established.

The protocol flow, alongside all the involved actors, is captured in
{{figure-cc-example}} where the TLS client is the user (the relying
party) while the TLS server is co-located with the TEE-hosted
confidential workload (the attester).

The flow starts with the client initiating a verification session with a
trusted verifier.  The verifier returns the kinds of evidence it
understands and a nonce that will be used to challenge the attester.

The client starts the TLS handshake with the server by supplying the
attestation-related parameters it has obtained from the verifier.  If
the server supports one of the offered evidence types, it will echo it
in the specular extension and proceed by invoking the local API to
request the attestation.  The returned evidence binds the identity key
with the platform identity and security state.  The server
then signs the handshake transcript with the (attested) identity key,
and sends the attestation evidence together with the signature over to
the client.

The client forwards the attestation evidence to the verifier using the
previously established session, obtains the attestation result and
checks it is acceptable according to its local policy.  If so, it
proceeds and verifies the handshake signature using the corresponding
public key (for example, using the PoP key in the KAT evidence
{{I-D.bft-rats-kat}}).

The attestation evidence verification combined with the verification of
the CertificateVerify signature provide confirmation that the presented
cryptographic identity is bound to the workload and platform identity,
and that the workload and platform are trustworthy.  Therefore, after
the handshake is finalized, the client can trust the workload on the
other side of the established secure channel to provide the required
confidential computing properties.

~~~~aasvg
                                             .------------------------.
.----------.        .--------.               | Server  |  Attestation |
| Verifier |        | Client |               |         |  Service     |
'--+-------'        '---+----'               '---+---------------+----'
   |                    |                        |               |
   |  POST /newSession  |                        |               |
   |<-------------------+                        |               |
   | 201 Created        |                        |               |
   | Location: /76839A9 |                        |               |
   | Body: {            |                        |               |
   |   nonce,           |                        |               |
   |   supp-media-types |                        |               |
   | }                  |                        |               |
   +------------------->|                        |               |
   |                    |                        |               |
.--+-----------.        |                        |               |
| TLS handshake |       |                        |               |
+--+------------+-------+------------------------+---------------+---.
|  |                    | ClientHello            |               |    |
|  |                    |  {...}                 |               |    |
|  |                    |  evidence_request(     |               |    |
|  |                    |    nonce,              |               |    |
|  |                    |    types(a,b,c)        |               |    |
|  |                    |  )                     |               |    |
|  |                    +----------------------->|               |    |
|  |                    | ServerHello            |               |    |
|  |                    |  {...}                 |               |    |
|  |                    | EncryptedExtensions    |               |    |
|  |                    |  {...}                 |               |    |
|  |                    |  evidence_request(     |               |    |
|  |                    |    type(a)             |               |    |
|  |                    |  )                     |               |    |
|  |                    |<-----------------------+               |    |
|  |                    |                        | attest_key(   |    |
|  |                    |                        |   nonce,      |    |
|  |                    |                        |   TIK         |    |
|  |                    |                        | )             |    |
|  |                    |                        +-------------->|    |
|  |                    |                        | CAB(KAT, PAT) |    |
|  |                    |                        |<--------------+    |
|  |                    |                        | sign(TIK,hs)  |    |
|  |                    |                        +-------------->|    |
|  |                    |                        |     sig       |    |
|  |                    |                        |<--------------+    |
|  |                    | Certificate(KAT,PAT)   |               |    |
|  |                    | CertificateVerify(sig) |               |    |
|  |                    | Finished               |               |    |
|  |                    |<-----------------------+               |    |
|  | POST /76839A9E     |                        |               |    |
|  | Body: {            |                        |               |    |
|  |   type(a),         |                        |               |    |
|  |   CAB              |                        |               |    |
|  | }                  |                        |               |    |
|  |<-------------------+                        |               |    |
|  | Body: {            |                        |               |    |
|  |   att-result: AR{} |                        |               |    |
|  | }                  |                        |               |    |
|  +------------------->|                        |               |    |
|  |                    +---.                    |               |    |
|  |                    |    | verify AR{}       |               |    |
|  |                    |<--'                    |               |    |
|  |                    +---.                    |               |    |
|  |                    |    | verify sig        |               |    |
|  |                    |<--'                    |               |    |
|  |                    |       Finished         |               |    |
|  |                    +----------------------->|               |    |
|  |                    |                        |               |    |
 '-+--------------------+------------------------+---------------+---'
                        |    application data    |
                        |<---------------------->|
                        |                        |
~~~~
{: #figure-cc-example title="Example Exchange with Server as Attester."}

## IoT Device Onboarding

In this example, an IoT is onboarded to a cloud service provider (or to a
network operator). In this scenario there is typically no a-priori
relationship between the device and the cloud service provider that 
will remote manage the device.

In such scenario, the cloud service provider wants to make sure
that the device runs the correct version of firmware, has not been 
rooted, is emulated, or cloned.

The protocol flow is shown in {{figure-iot-example}} where the client 
is the attester while the server is the relying party.

The flow starts with the client initiating a TLS exchange with the TLS
server operated by the cloud service provider. The client indicates
what evidence types it supports.

The server obtains a nonce from the verifier, in real-time or from a
reserved nonce range, and returns it to the client alongside the
selected evidence type. Since the evidence will be returned in the
Certificate message the server has to request mutual authentication
via the CertificateRequest message.

The client, when receiving the EncryptedExtension with the 
evidence_proposal, will proceed by invoking a local API to
request the attestation.  The returned evidence binds the identity key
with the workload and platform identity and security state.  The client
then signs the handshake transcript with the (attested) identity key,
and sends the evidence together with the signature over to
the server.

The server forwards the attestation evidence to the verifier, obtains 
the attestation result and checks it is acceptable according to its 
local policy. The evidence verification combined with the verification of
the CertificateVerify signature provide confirmation that the presented
cryptographic identity is bound to the platform identity, and that the 
platform is trustworthy. 

If successful, the server proceeds with the application layer protocol 
exchange. If, for some reason, the attestation result is not satisfactory
the TLS server will terminate the exchange. 

~~~~aasvg
.--------------------------.
| Attestation   |  Client  |            .--------.         .----------.
| Service       |          |            | Server |         | Verifier |
'--+----------------+------'            '----+---'         '-----+----'
   |                |                        |                   |
.--+-----------.    |                        |                   |
| TLS handshake |   |                        |                   |
+--+------------+---+------------------------+-------------------+---.
|  |                |                        |                   |    |
|  |                | ClientHello            |                   |    |
|  |                |  {...}                 |                   |    |
|  |                |  evidence_proposal(    |                   |    |
|  |                |    types(a,b,c)        |                   |    |
|  |                |  )                     |                   |    |
|  |                +----------------------->|                   |    |
|  |                |                        |                   |    |
|  +                | ServerHello            | POST /newSession  |    |
|  |                |  {...}                 +------------------>|    |
|  |                |                        | 201 Created       |    |
|  |                |                        | Location: /76839  |    |
|  |                |                        | Body: {           |    |
|  |                |                        |   nonce,          |    |
|  |                | EncryptedExtensions    |   types(a,b,c)    |    |
|  |                |  {...}                 | }                 |    |
|  |                |  evidence_proposal(    |<------------------+    |
|  |                |    nonce,              |                   |    |
|  |                |    type(a)             |                   |    |
|  |                |  )                     |                   |    |
|  |                | CertificateRequest     |                   |    |
|  |                | Certificate            |                   |    |
|  |  attest_key(   | CertificateVerify      |                   |    |
|  |    nonce,      | Finished               |                   |    |
|  |    TIK         |<-----------------------+                   |    |
|  |  )             |                        |                   |    |
|  |<---------------+                        |                   |    |
|  |  CAB(KAT, PAT) |                        |                   |    |
|  +--------------->|                        |                   |    |
|  |  sign(TIK,hs)  |                        |                   |    |
|  |<---------------+                        |                   |    |
|  |      sig       |                        |                   |    |
|  +--------------->| Certificate(KAT,PAT)   |                   |    |
|  |                | CertificateVerify(sig) |                   |    |
|  |                | Finished               |                   |    |
|  |                +----------------------->|                   |    |
|  |                |                        |                   |    |
|  |                |                        | POST /76839A9E    |    |
|  |                |                        | Body: {           |    |
|  |                |                        |   type(a),        |    |
|  |                |                        |   CAB             |    |
|  |                |                        | }                 |    |
|  |                |                        +------------------>|    |
|  |                |                        | Body: {           |    |
|  |                |                        |  att-result: AR{} |    |
|  |                |                        | }                 |    |
|  |                |                        |<------------------+    |
|  |                |                        +---.               |    |
|  |                |                        |    | verify AR{}  |    |
|  |                |                        |<--'               |    |
|  |                |                        +---.               |    |
|  |                |                        |    | verify sig   |    |
|  |                |                        |<--'               |    |
|  |                |                        |                   |    |
|  |                |                        |                   |    |
|  |                |                        |                   |    |
|  |                |                        |                   |    |
'--+----------------+------------------------+-------------------+---'
                    |    application data    |
                    |<---------------------->|
                    |                        |
~~~~
{: #figure-iot-example title="Example Exchange with Client as Attester."}


# Security Considerations {#sec-cons}

TBD.

# IANA Considerations

## TLS Extensions

IANA is asked to allocate two new TLS extensions, evidence_request
and evidence_proposal, from the "TLS ExtensionType Values"
subregistry of the "Transport Layer Security (TLS) Extensions"
registry {{TLS-Ext-Registry}}.  These extensions are used in
the ClientHello and the EncryptedExtensions messages. The
values carried in these extensions are taken from TBD.

## TLS Alerts

IANA is requested to allocate a value in the "TLS Alerts"
subregistry of the "Transport Layer Security (TLS) Parameters" registry
{{TLS-Param-Registry}} and populate it with the following entry:

- Value: TBD
- Description: unsupported_evidence
- DTLS-OK: Y
- Reference: [This document]
- Comment:

## TLS Certificate Types

IANA is requested to allocate a new value in the "TLS Certificate Types"
subregistry of the "Transport Layer Security (TLS) Extensions"
registry {{TLS-Ext-Registry}}, as follows:

-   Value: TBD2
-   Description: Attestation
-   Reference: [This document]
   
--- back

# History

RFC EDITOR: PLEASE REMOVE THE THIS SECTION

## draft-fossati-tls-attestation-02

- Focus on the background check model
- Added examples
- Updated introduction
- Moved attestation format-specific content to related drafts.
    
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

