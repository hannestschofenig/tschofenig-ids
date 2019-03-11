---
title: Arm's Platform Security Architecture (PSA) Attestation Token
abbrev: PSA Attestation Token
docname: draft-tschofenig-rats-psa-token-latest
category: std
updates: 6347

ipr: pre5378Trust200902
area: Security
workgroup: RATS
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
       ins: S. Frost
       name: Simon Frost
       organization: Arm Limited
       email: Simon.Frost@arm.com
 -
       ins: M. Brossard
       name: Mathias Brossard
       organization: Arm Limited
       email: Mathias.Brossard@arm.com


normative:
  RFC2119:
  I-D.mandyam-eat:
  RFC8392: 
  RFC8152: 
  RFC7049: 
informative:
  TF-M:
    author:
      org: Linaro
    title: Trusted Firmware
    target: https://www.trustedfirmware.org
    date: 2019
  IANA-CWT:
    author:
      org: IANA
    title: CBOR Web Token (CWT) Claims
    target: https://www.iana.org/assignments/cwt/cwt.xhtml
    date: 2019
  EAN-13: 
    author:
      org: GS1
    title: International Article Number - EAN/UPC barcodes
    target: https://www.gs1.org/standards/barcodes/ean-upc
    date: 2019
  PSA: 
    author:
      org: Arm
    title: Platform Security Architecture Resources
    target: https://www.arm.com/why-arm/architecture/platform-security-architecture/psa-resources
    date: 2019	
  PSA-FF: 
    author:
      org: Arm
    title: Platform Security Architecture Firmware Framework 1.0 (PSA-FF)
    target: https://pages.arm.com/psa-resources-ff.html
    date: 20. Feb. 2019	
  PSA-SM: 
    author:
      org: Arm
    title: Platform Security Architecture Security Model 1.0 (PSA-SM)
    target: https://pages.arm.com/psa-resources-sm.html
    date: 19. Feb. 2019	

--- abstract

The insecurity of IoT systems is a widely known and discussed problem. The Arm Platform Security Architecture (PSA) is 
being developed to address this challenge and make it easier to build secure systems.

This document specifies token format and claims used in the attestation 
API of the Arm Platform Security Architecture (PSA).

At its core, the Entity Attestation Token (EAT) format is used and populated with a set of claims. This specification
describes what claims are used by the PSA and what has been implemented within Arm Trusted Firmware-M. 

--- middle


#  Introduction

Modern hardware for Internet of Things devices contain trusted execution environments and in case of the Arm v8-M architecture TrustZone support. TrustZone on these low end microcontrollers allows the separation between a normal world and a secure world where security sensitive code resides in the secure world and is executed by applications running on the normal world using a well-defined API. Various APIs have been developed by Arm as part of the Platform Security Architecture {{PSA}}; this document focuses on the functionality provided by the attestation API. Since the tokens exposed via the attestation API are also consumed by services outside the device interopability needs arise. In this specification these interoperability needs are addressed by a combination of 

- a set of claims encoded in CBOR, 
- embedded in a CBOR Web Token (CWT), 
- protected by functionality offered by the CBOR Object Signing and Encryption (COSE) specification.

{{architecture}} shows the architecture graphically. Apps on the IoT device communicate with services 
on the secure world using a defined API. The attestation API exposes tokens, as described in this document, 
and those tokens may be presented to network or application services. 

~~~~
                        +-----------------+------------------+
                        |  Normal World   |   Secure World   |
                        |                 |        +-+       |
                        |                 |        |A|       |
                        |                 |        |T|       |
                        |                 |        |T|       |
                        |                 |        |E| +-+   |
                        |                 |    +-+ |S| |S|   |
                        |                 |    |C| |T| |T|   |
+----------+            |                 |    |R| |A| |O|   |
| Network  |            | +----------+    |    |Y| |T| |R|   |
| and App  |<=============| Apps     | +--+--+ |P| |I| |A|   |
| Services |            | +----------+ |P |  | |T| |O| |G|   |
+----------+            | +----------+ |S |  | |O| |N| |E|   |
                        | |Middleware| |A |  | +-+ +-+ +-+   |
                        | +----------+ |  |  | +----------+  |
                        | +----------+ |A |  | |          |  |
                        | |          | |P |  | | TF-M Core|  |
                        | | RTOS and | |I |  | +----------+  |
                        | | Drivers  | +--+--+ +----------+  |
                        | |          |    |    |          |  |
                        | +----------+    |    |Bootloader|  |
                        |                 |    +----------+  |
                        +-----------------+------------------+
                        |          H A R D|W A R E           |
                        +-----------------+------------------+

                               Internet of Things Device
~~~~
{: #architecture title="Software Architecture"}


# Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

# Information Model

{{info-model}} describes the utilized claims.

| Claim | Mandatory | Description |
| ------|:---------:|-----------|
| Challenge | Yes |  Input object from the caller. For example, this can be a cryptographic nonce, a hash of locally attested data, or both. The length must be 32, 48, or 64 bytes. |
| Instance ID | Yes | Represents the unique identifier of the instance. It is a hash of the public key corresponding to the Initial Attestation Key. | 
| Verification service indicator | No | Information used by a relying party to locate a validation service for the token or a location to obtain known good values. The value is a text string that can be used to locate the service or a URL specifying the address of the service. |
| Profile definition | No | Contains the name of a document that describes the 'profile' of the report. A profile document contains a full description of the claims that are supported in the token, their expected presence and details of token signing. The document name may include versioning. The value for this specification is PSA_IOT_PROFILE_1. | 
| Implementation ID | Yes | Represents the original implementation signer of the attestation key and identifies the contract between the report and verification. A verification service will use this claim to locate the details of the verification process. |
| Client ID | Yes | Represents the Partition ID of the caller. It is a signed integer whereby negative values represent callers from the NSPE and where positive IDs represent callers from the SPE. The full definition of the partition ID is defined in the PSA Firmware Framework (PSA-FF) {{PSA-FF}}.  |
|Security Lifecycle | Yes |  Represents the current lifecycle state of the PSA RoT. The state is represented by a 16-bit unsigned integer that is divided to convey a major state and a minor state. A major state is defined by PSA-SM. A minor state is 'IMPLEMENTATION DEFINED'. The encoding is: version[15:8] - PSA lifecycle state, and version[7:0] - IMPLEMENTATION DEFINED state. The PSA lifecycle states are listed below. For PSA, a remote verifier can only trust reports from the PSA RoT when it is in SECURED, NON_PSA_ROT_DEBUG or RECOVERABLE_PSA_ROT_DEBUG major states. |
| Hardware version | No | Provides metadata linking the token to the GDSII that went to fabrication for this instance. It can be used to link the class of chip and PSA RoT to the data on a certification website. It must be represented as a thirteen-digit {{EAN-13}} |
| Boot seed | Yes | Represents a random value created at system boot time that will allow differentiation of reports from different system sessions. |
| Software components | Yes (unless the No Software Measurements claim is specified) | A list of software components that represent the entire software state of the system. This claim is recommended in order to comply with the rules outlined in the {{PSA-SM}}. The software components are further explained below. |
| No Software Measurements | Yes (if no software components specified) | In the event that the implementation does not contain any software measurements then the Software Components claim above should be omitted, instead it will be mandatory to include this claim to indicate this is a deliberate state. |
{: #info-model title="Information Model of PSA Attestation Claims."} 

The PSA lifecycle states consist of the following values:

- UNKNOWN (0x1000u)
- PSA_ROT_PROVISIONING (0x2000u)
- SECURED (0x3000u)
- NON_PSA_ROT_DEBUG (0x4000u)
- RECOVERABLE_PSA_ROT_DEBUG (0x5000u)
- PSA_LIFECYCLE_DECOMMISSIONED (0x6000u)


{{software-components}} shows the structure of each software component entry in the Software Components claim. 

| Key ID | Type | Mandatory | Description |
| ------|:---------:|:---------:-----------|
| 1 | Measurement Type | No | A short string representing the role of this software component (e.g. 'BL' for bootloader). |
| 2 | Measurement value | Yes | Represents a hash of the invariant software component in memory at startup time. The value must be a cryptographic hash of 256 bits or stronger. | 
| 3 | Reserved | No | Reserved | 
| 4 | Version | No | The issued software version in the form of a text string. The value of this claim will correspond to the entry in the original signed manifest of the component. |
|5 | Signer ID | Yes | The hash of a signing authority public key for the software component. The value of this claim will correspond to the entry in the original manifest for the component. |
| 6 | Measurement description | No | Description of the software component, which represents the way in which the measurement value of the software component is computed. The value will be a text string containing an abbreviated description (or name) of the measurement method which can be used to lookup the details of the method in a profile document. This claim will normally be excluded, unless there was an exception to the default measurement described in the profile for a specific component. |
{: #software-components title="Software Components Claims."} 

The following measurement types are current defined:
 
 - BL (a bootloader)
 - PRoT (a component of the PSA Root of Trust)
 - ARoT (a component of the Application Root of Trust)
 - App (a component of the NSPE application)
 - TS (a component of a trusted subsystem)

# Token Encoding

The report is represented as a token, which must be formatted in accordance to the Entity Attestation Token (EAT) {{I-D.mandyam-eat}}. The token consists of a series of claims declaring evidence as to the nature of the instance of hardware and software. The claims are encoded in CBOR {{RFC7049}} format.

# Claims {#claims}

The token is modelled to include custom values that correspond to the following claims suggested in the EAT specification. 

- nonce (mandatory); arm_psa_nonce is used instead
- UEID (mandatory); arm_psa_UEID is used instead
- origination (recommended); arm_psa_origination is used instead

As noted, some fields must be at least 32 bytes long to provide sufficient cryptographic strength.

| Claim Key | Claim Description | Claim Name | CBOR Value Type |
| ------|:---------:|:---------:|:-----------|
| -75000 | Profile Definition | arm_psa_profile_id | Text string |
| -75001 | Client ID | arm_psa_partition_id | Unsigned integer or Negative integer |
| -75002 | Security Lifecycle | arm_psa_security_lifecycle | Unsigned integer |
| -75003 | Implementation ID | arm_psa_implementation_id | Byte string (>=32 bytes) |
| -75004 | Boot seed | arm_psa_boot_seed | Byte string (>=32 bytes) |
| -75005 | Hardware version | arm_psa_hw_version | Text string |
| -75006 | Software components - (compound map claim) | arm_psa_sw_components  | Array of map entries. |
| -75007 | No software measurements | arm_psa_no_sw_measurements  | Unsigned integer |
| -75008 | Challenge | arm_psa_nonce  | Byte string |
| -75009 | UEID | arm_psa_UEID  | Byte string |
| -75010 | Verification service indicator | arm_psa_origination | Byte string |

Each map entry of the software component claim MUST have the following types for each key value:

 1. Text string (type)
 2. Byte string  (measurement, >=32 bytes)
 3. Reserved
 4. Text string (version)
 5. Byte string (signer ID, >=32 bytes)
 6. Text string (measurement description)
 
The following key values will be present in the software components claim: 1 (Type), 2 (Measurement Value), 4 (Version) and 5 (Signer ID). Keys 3 (Reserved) and 6 (Measurement Description) will not be present. Instead of a referenced Measurement Description it is defined that all cases, the software measurement value is taken as a SHA256 hash of the software image, prior to it executing in place.

# Example

~~~
{
  / nonce /  -75008:h'0100010203060708....41516191a1b1c1d1e1f',
  / UEID /   -75009:h'0100010203060708....41516191a1b1c1d1e1f',
  / origination / -75010:'psa_verifier',
  / profile /     -75000:'PSA_IoT_PROFILE_1',
  / clientID /    -75001:-1,
  / security lifecycle / -75002:12288,
  / boot seed /   -75004:h'0100010203060708....41516191a1b1c1d1e1f',

  / software components/ -75006:
      [
       {
/ type /          1: 'BL',
/ measurement /   2: h'0100010203060708....41516191a1b1c1d1e1f',
/ version /       4: '3.1.4',
/ signerID /      5: h'0100010203060708....41516191a1b1c1d1e1f'
       },
       {
/ type /          1: 'PRoT',
/ measurement /   2: h'0100010203060708....41516191a1b1c1d1e1f',
/ version /       4: '1.1',
/ signerID /      5: h'0100010203060708....41516191a1b1c1d1e1f'
       },
       {
/ type /          1: 'ARoT',
/ measurement /   2: h'0100010203060708....41516191a1b1c1d1e1f',
/ version /       4: '1.0',
/ signerID /      5: h'0100010203060708....41516191a1b1c1d1e1f'
       },
       {
/ type /          1: 'App',
/ measurement /   2: h'0100010203060708....41516191a1b1c1d1e1f',
/ version /       4: '2.2',
/ signerID /      5: h'0100010203060708....41516191a1b1c1d1e1f'
       }
     ]
}
~~~

#  Security and Privacy Considerations {#sec-cons}

This specification re-uses the CWT and the EAT specification. Hence, the 
security and privacy considerations of those specifications apply here as well. 

Since CWTs offer different ways to protect the token this specification profiles those
options and only uses public key cryptography. The token MUST be signed following 
the structure of the COSE specification {{RFC8152}}. 
The COSE type MUST be COSE-Sign1.

Attestation tokens contain information that may be unique to a device and 
therefore they may allow single out an individual device for tracking purposes. 
Implementation must take to ensure that only those claims are included that fulfil 
the purpose of the application and that users of those devices consent to the 
data sharing. 

#  IANA Considerations

IANA is requested to allocate the claims defined in {{claims}} to the {{RFC8392}}
created CBOR Web Token (CWT) Claims registry {{IANA-CWT}}. The change controller 
are the authors and the reference is this document. 

--- back


# Contributors

We would like to thank the following supporters for their contributions: 

~~~
* Laurence Lundblade
  lgl@securitytheory.com
~~~

# Reference Implementation 

Trusted Firmware M (TF-M) {{TF-M}} is the name of the open source project that provides 
a reference implementation of PSA APIs, created for the latest Arm v8-M microcontrollers 
with TrustZone technology. TF-M provides foundational firmware components that silicon 
manufacturers and OEMs can build on (including trusted boot, secure device initialisation 
and secure function invocation).

