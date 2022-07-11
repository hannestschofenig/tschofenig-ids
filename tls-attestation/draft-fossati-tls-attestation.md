---
title: Using Attestation in Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS)
abbrev: Attestation in TLS/DTLS
docname: draft-fossati-tls-attestation-00
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
informative:
  RFC8747:
  RFC7250:
  I-D.ietf-rats-architecture:
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

--- abstract

Various attestation technologies have been developed and formats have been standardized.
Examples include the Entity Attestation Token (EAT) and Trusted Platform Modules (TPMs).
Once attestation information has been produced on a device it needs to be communicated
to a relying party. This information exchange may happen at different layers in the 
protocol stack.

This specification provides a generic way of passing attestation information in the 
TLS handshake.

--- middle


#  Introduction

Attestation is the process by which an entity produces evidence about itself
that another party can use to evaluate the trustworthiness of that entity. 
One format of encoding evidence is standardized with the Entity Attestation 
Token (EAT) {{I-D.ietf-rats-eat}} but there are other formats, such as 
attestation produced by Trusted Platform Modules (TPMs) {{TPM1.2}} {{TPM2.0}}.

This specification defines how to convey attestation information in the 
TLS handshake with different encodings being supported. This specification
standardizes two attestation formats -- EAT and TPM-based attestation.

Note: This initial version of the specification focuses on EAT-based attestation.
Future versions will also define TPM-based attestation.

# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The following terms are used in this document:

- Root of Trust (RoT): A set of software and/or hardware components that need 
to be trusted to act as a security foundation required for accomplishing the
security goals. In our case, the RoT is expected to offer the functionality 
for attesting to the state of the platform.

- Attestation Key (AK): Cryptographic key belonging to the RoT that is only used
 to sign attestation tokens. 

- Platform Attestation Key (PAK): An AK used specifically for signing attestation 
tokens relating to the state of the platform.

- Key Attestation Key (KAK): An AK used specifically for signing KATs. In some 
systems only a single AK is used. In that case the AK is used as a PAK and a KAK.

- TLS Identity Key (TIK): The KIK consists of a private and a public key. The private key is used in the CertificateVerify message during the TLS handshake. The public key is included in the Key Attestation Token.

- Attestation Token (AT): A collection of claims that a RoT assembles (and signs) with the purpose of informing - in a verifiable way - Relying Parties about the identity and state of the platform. Essentially a type of "Evidence" as per the RATS architecture terminology.

- Platform Attestation Token (PAT): An AT containing claims relating to the state of the software running on the platform. The process of generating a PAT typically involves gathering data during measured boot.

- Key Attestation Token (KAT, read as "Kate"): An AT containing a claim with a proof-of-possession (PoP) key. The KAT may also contain other claims, such as those indicating its validity. The KAT is signed by the KAK. The attestation 
service part of the RoT conceptually acts as a local certification authority since the KAT behaves like a certificate.

- Combined Attestation Bundle (CAB): A structure used to bundle a KAT and a PAT together for transport in the TLS handshake. If the KAT already includes a PAT, in form of a nested token, then it already corresponds to a CAB.


# Overview

The Remote Attestation Procedures (RATS) architecture {{I-D.ietf-rats-architecture}}
defines two types of interaction models for attestation, 
namely the passport model and the background-check model. The subsections below
explain the difference in their interactions.

To simplify the description in this section we focus on the use case where the 
client is the attester and the server is the relying party. Hence, only the
client_attestation_type extension is discussed. The verifier is not shown in 
the diagrams. The described mechanism allows the roles to be reversed.

As typical with new features in TLS, the client indicates support for the new 
extension in the ClientHello. The client_attestation_type extension lists the
supported attestation formats. The server, if it supports the extension and one of the
attestation formats, it confirms the use of the feature.

Note: The newly introduced extension also allows nonces to be exchanged. Those
nonces are used for guaranteeing freshness of the generated attestation tokens.

When the attestation extension is successfully negotiated, the content of the
Certificate message is replaced with attestation information described in this
document.

A peer has to demonstrate possession of the private key via the CertificateVerify
message. While attestation information is signed by the attester, it typically
does not contain a public key (for example via a proof-of-possession key claim
{{RFC8747}}).

The attestation service on a device, which creates the attestation information, 
is unaware of the TLS exchange and the attestation service does not directly 
sign externally provided data, as it would be required to compute the CertificateVerify message.

Hence, the following steps happen:

The client generates the TIK, which are referred here as skT and pkT, for example
using the following API call:

~~~~
key_id = GenerateKeyPair(alg_id)
~~~~

The private key would be created and stored by the crypto hardware supported by
the device (rather than the TLS client in software). 

Next, the attestation service needs to be triggered to create a Platform
Attestation Token (PAT) and the Key Attestation Token (KAT). The Key Attestation 
Token (KAT) includes a claim containing the
public key of the TIK (pkT). The KAT is then signed with the Key Attestation
Key (KAK).

To ensure freshness of the PAT and the KAT a nonce is provided by the relying 
party / verifier. Here is the symbolic API call to request a KAT and a PAT, which 
are concatinated together as the CAB. 

~~~~
cab = createCAB(key_id, nonce)
~~~~

Once the Certificate message containing the CAB has been sent, the CertificateVerify
has to be created and it requires access to the private key. The signature operation
uses the private key of the TIK (skT).

The recipient of the Certificate and the CertificateVerify messages first extracts 
the PAT and the KAT from the Certificate message. The PAT and the KAT need to be 
conveyed to the verification service, whereby the following checks are made:

- The signature protecting the PAT passes verification when using available trust anchor(s).
- The PAT has not been replayed, which can be checked by comparing the nonce included
  in one of the claims and matching it against the nonce provided to the attester.
- The claims in the PAT are matched against stored reference values.
- The signature protecting the KAT passes verification. 
- The claims in the KAT are validated, if needed.

Once all these steps are completed, the verifier produces the attestation result and
includes (if needed) the TIK public key. 

In the subsections we will look at how the two message pattern fit align with the 
TLS exchange. 

## Attestation within the Passport Model

The passport model is described in Section 5.1 of {{I-D.ietf-rats-architecture}}. A key feature 
of this model is that the attester interacts with the verification service before initiating 
the TLS exchange. It sends evidence to the verification service, which then returns the 
attestation result (including the TIK public key).

The example exchange in {{figure-passport-model}} shows how a client
provides attestation to the server by utilizing EAT tokens {{I-D.ietf-rats-eat}}.
With the ClientHello the TLS client needs to indicate that it supports the EAT-based
attestation format. The TLS server acknowledges support for this attestation type in
the EncryptedExtensions message. 

In the Certificate message the TLS client transmits the attestation result to the TLS 
server, in form a CAB (i.e. a concatinated PAT and KAT).

The TLS client then creates the CertificateVerify message by asking the crypto 
service to sign the TLS handshake message transcript with the TIK private key. 
The TLS server then verifies this message by utilizing the TIK public key.

~~~~
    Client                                           Server

Key  ^ ClientHello
Exch | + client_attestation_type(eat)
     |
     |
     v                         -------->
                                                  ServerHello ^ KeyExch
                                        {EncryptedExtensions} ^ Server
                               + client_attestation_type(eat) |
                                         {CertificateRequest} v Params
                                                {Certificate} ^
                                          {CertificateVerify} | Auth
                                                   {Finished} v
                               <--------  [Application Data*]
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
~~~~
{: #figure-passport-model title="Example Exchange with the Passport Model."}


## Attestation within the Background Check Model

The background check model is described in Section 5.2 of {{I-D.ietf-rats-architecture}}. 

The message exchange of the background check model differs from the passport 
model because the TLS server needs to provide a nonce in the ServerHello to the 
TLS client so that the attestation service can feed the nonce into the generation
of the PAT. The TLS server, when receiving the CAB, will have to contact the 
verification service.

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + client_attestation_type(eat)
     |
     |
     v                         -------->
                                                  ServerHello  ^ Key
                                 client_attestation_type(eat)  | Exch
                                                      + nonce  v
                                        {EncryptedExtensions}  ^  Server
                                         {CertificateRequest}  v  Params
                                                {Certificate}  ^
                                          {CertificateVerify}  | Auth
                                                   {Finished}  v
                               <--------  [Application Data*]
     ^ {Certificate}
Auth | {CertificateVerify}
     v {Finished}              -------->
       [Application Data]      <------->  [Application Data]
~~~~
{: #figure-background-check-model title="Example Exchange with the Background Check Model."}

# TLS Attestation Type Extension

This document defines a new extension to carry the assertion types.
The extension is conceptually similiar to the 'server_certificate_type'
and the 'server_certificate_type' defined by {{RFC7250}}.

~~~~
   struct {
           select(ClientOrServerExtension) {
               case client:
                 CertificateType client_assertion_types<1..2^8-1>;
                 opaque nonce<0..2^16-1>;
                 
               case server:
                 CertificateType client_assertion_type;
                 opaque nonce<0..2^16-1>;                 
           }
   } ClientAssertionTypeExtension;

   struct {
           select(ClientOrServerExtension) {
               case client:
                 CertificateType server_assertion_types<1..2^8-1>;
                 opaque nonce<0..2^16-1>;                 

               case server:
                 CertificateType server_assertion_type;
                 opaque nonce<0..2^16-1>;                                  
           }
   } ServerAssertionTypeExtension;
~~~~
{: #figure-assertion-type title="AssertionTypeExtension Structure."}

The Certificate payload is used as a container, as shown in 
{{figure-certificate}}.  The shown Certificate structure is
an adaptation of {{RFC8446}}.

~~~~
      struct {
          select (certificate_type) {
              case RawPublicKey:
                /* From RFC 7250 ASN.1_subjectPublicKeyInfo */
                opaque ASN1_subjectPublicKeyInfo<1..2^24-1>;

                /* assertion type defined in this document */
              case EAT:
                opaque cab<1..2^24-1>;
              
                /* assertion type defined in a future version */
              case TPM:
                opaque tpmStmtFormat<1..2^24-1>;
              
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

To simplify parsing of an EAT-based attestation payload,
the PAT and the KAT are typed.

# TLS Client and Server Handshake Behavior {#behavior}

   This specification extends the ClientHello and the EncryptedExtensions
   messages, according to {{RFC8446}}.

   The high-level message exchange in {{figure-overview}} shows the
   client_assertion_type and server_assertion_type extensions added
   to the ClientHello and the EncryptedExtensions messages.

~~~~
       Client                                           Server

Key  ^ ClientHello
Exch | + key_share*
     | + signature_algorithms*
     | + psk_key_exchange_modes*
     | + pre_shared_key*
     | + client_assertion_type
     v + server_assertion_type
     -------->
                                                  ServerHello  ^ Key
                                                 + key_share*  | Exch
                                            + pre_shared_key*  v
                                        {EncryptedExtensions}  ^  Server
                                      + client_assertion_type  |
                                      + server_assertion_type                                        
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
   
#  Security and Privacy Considerations {#sec-cons}

TBD.

#  IANA Considerations

TBD: Create new registry for attestation types.

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

