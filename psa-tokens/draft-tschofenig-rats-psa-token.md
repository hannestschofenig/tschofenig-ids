---
title: Arm's Platform Security Architecture (PSA) Attestation Token
abbrev: PSA Attestation Token
docname: draft-tschofenig-rats-psa-token-00
category: std

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
 -
       ins: A. Shaw
       name: Adrian Shaw
       organization: Arm Limited
       email: Adrian.Shaw@arm.com
 -
       ins: T. Fossati
       name: Thomas Fossati
       organization: Arm Limited
       email: thomas.fossati@arm.com	  	   
	   
normative:
  RFC2119:
  RFC8392: 
  RFC8152: 
  RFC7049: 
informative:
  I-D.ietf-rats-eat:
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
being developed to address this challenge by making it easier to build secure systems.

This document specifies token format and claims used in the attestation 
API of the Arm Platform Security Architecture (PSA).

At its core, the Entity Attestation Token (EAT) format is used and populated with a set of claims. This specification
describes what claims are used by the PSA and what has been implemented within Arm Trusted Firmware-M. 

--- middle


#  Introduction

Modern hardware for Internet of Things devices contain trusted execution environments and in case of the Arm v8-M architecture TrustZone support. TrustZone on these low end microcontrollers allows the separation between a normal world and a secure world where security sensitive code resides in the secure world and is executed by applications running on the normal world using a well-defined API. Various APIs have been developed by Arm as part of the Platform Security Architecture {{PSA}}; this document focuses on the functionality provided by the attestation API. Since the tokens exposed via the attestation API are also consumed by services outside the device, interoperability needs arise. In this specification these interoperability needs are addressed by a combination of

- a set of claims encoded in CBOR, 
- embedded in a CBOR Web Token (CWT), 
- protected by functionality offered by the CBOR Object Signing and Encryption (COSE) specification.

Further details on concepts expressed below can be found within the PSA Security Model documentation {{PSA-SM}}.

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
                        | |          | |P |  | |   SPM    |  |
                        | | RTOS and | |I |  | +----------+  |
                        | | Drivers  | +--+--+ +----------+  |
                        | |          |    |    |   Boot   |  |
                        | +----------+    |    |  Loader  |  |
                        |                 |    +----------+  |
                        +-----------------+------------------+
                        |          H A R D|W A R E           |
                        +-----------------+------------------+

                               Internet of Things Device
~~~~
{: #architecture title="Software Architecture"}

# Conventions and Terminology

{::boilerplate bcp14}

## Glossary

RoT
: Root of Trust, the minimal set of software, hardware and data that has to be implicitly trusted in the platform - there is no software or hardware at a deeper level that can verify that the Root of Trust is authentic and unmodified.

SPE
: Secure Processing Environment, a platform's processing environment for software that provides confidentiality and integrity for its runtime state, from software and hardware, outside of the SPE. Contains the Secure Partition Manager (SPM), the Secure Partitions and the trusted hardware.

NSPE
: Non Secure Processing Environment, the security domain outside of the SPE, the Application domain, typically containing the application firmware and hardware.


# Information Model

{{info-model}} describes the utilized claims.

| Claim | Mandatory | Description |
|------|:---------:|-----------|
| Auth Challenge | Yes |  Input object from the caller. For example, this can be a cryptographic nonce, a hash of locally attested data. The length must be 32, 48, or 64 bytes. |
| Instance ID | Yes | Represents the unique identifier of the instance. It is a hash of the public key corresponding to the Initial Attestation Key. The full definition is in {{PSA-SM}}. |
| Verification Service Indicator | No | A hint used by a relying party to locate a validation service for the token. The value is a text string that can be used to locate the service or a URL specifying the address of the service. A verifier may choose to ignore this claim in favor of other information.|
| Profile Definition | No | Contains the name of a document that describes the 'profile' of the report. The document name may include versioning. The value for this specification is PSA_IOT_PROFILE_1. |
| Implementation ID | Yes | Uniquely identifies the underlying immutable PSA RoT. A verification service can use this claim to locate the details of the verification process. Such details include the implementation's origin and associated certification state. |
| Client ID | Yes | Represents the Partition ID of the caller. It is a signed integer whereby negative values represent callers from the NSPE and where positive IDs represent callers from the SPE. The full definition of the partition ID is given in {{PSA-FF}}. |
| Security Lifecycle | Yes | Represents the current lifecycle state of the PSA RoT. The state is represented by an integer that is divided to convey a major state and a minor state. A major state is mandatory and defined by {{PSA-SM}}. A minor state is optional and 'IMPLEMENTATION DEFINED'. The encoding is: version[15:8] - PSA security lifecycle state, and version[7:0] - IMPLEMENTATION DEFINED state. The PSA lifecycle states are listed below. For PSA, a remote verifier can only trust reports from the PSA RoT when it is in SECURED or NON_PSA_ROT_DEBUG major states. |
| Hardware version | No | Provides metadata linking the token to the GDSII that went to fabrication for this instance. It can be used to link the class of chip and PSA RoT to the data on a certification website. It must be represented as a thirteen-digit {{EAN-13}} |
| Boot Seed | Yes | Represents a random value created at system boot time that will allow differentiation of reports from different boot sessions. |
| Software Components | Yes (unless the No Software Measurements claim is specified) | A list of software components that represent all the software loaded by the PSA Root of Trust. This claim is needed for the rules outlined in {{PSA-SM}}. The software components are further explained below. |
| No Software Measurements | Yes (if no software components specified) | In the event that the implementation does not contain any software measurements then the Software Components claim above can be omitted but instead it will be mandatory to include this claim to indicate this is a deliberate state. This claim is intended for devices that are not compliant with {{PSA-SM}}.|
{: #info-model title="Information Model of PSA Attestation Claims."} 

The PSA lifecycle states consist of the following values:

- PSA_LIFECYCLE_UNKNOWN (0x0000u)
- PSA_LIFECYCLE_ASSEMBLY_AND_TEST (0x1000u)
- PSA_LIFECYCLE_PSA_ROT_PROVISIONING (0x2000u)
- PSA_LIFECYCLE_SECURED (0x3000u)
- PSA_LIFECYCLE_NON_PSA_ROT_DEBUG (0x4000u)
- PSA_LIFECYCLE_RECOVERABLE_PSA_ROT_DEBUG (0x5000u)
- PSA_LIFECYCLE_DECOMMISSIONED (0x6000u)

{{software-components}} shows the structure of each software component entry in the Software Components claim. 

| Key ID | Type | Mandatory | Description |
| ------|:---------:|:---------:|-----------|
| 1 | Measurement Type | No | A short string representing the role of this software component (e.g. 'BL' for Boot Loader). |
| 2 | Measurement value | Yes | Represents a hash of the invariant software component in memory at startup time. The value must be a cryptographic hash of 256 bits or stronger. | 
| 3 | Reserved | No | Reserved | 
| 4 | Version | No | The issued software version in the form of a text string. The value of this claim will correspond to the entry in the original signed manifest of the component.|
| 5 | Signer ID | No | The hash of a signing authority public key for the software component. The value of this claim will correspond to the entry in the original manifest for the component. This can be used by a verifier to ensure the components were signed by an expected trusted source.  This field must be present to be compliant with {{PSA-SM}}.|
| 6 | Measurement description | No | Description of the software component, which represents the way in which the measurement value of the software component is computed. The value will be a text string containing an abbreviated description (or name) of the measurement method which can be used to lookup the details of the method in a profile document. This claim will normally be excluded, unless there was an exception to the default measurement described in the profile for a specific component. |
{: #software-components title="Software Components Claims."} 

The following measurement types are current defined:

- 'BL': a Boot Loader
- 'PRoT': a component of the PSA Root of Trust
- 'ARoT': a component of the Application Root of Trust
- 'App': a component of the NSPE application
- 'TS': a component of a Trusted Subsystem

# Token Encoding

The report is encoded as a COSE Web Token (CWT) {{RFC8392}}, similar to the Entity Attestation Token (EAT) {{I-D.ietf-rats-eat}}. The token consists of a series of claims declaring evidence as to the nature of the instance of hardware and software. The claims are encoded in CBOR {{RFC7049}} format.

# Claims {#claims}

The token is modelled to include custom values that correspond to the following claims suggested in the EAT specification:

- nonce (mandatory); arm_psa_nonce is used instead
- UEID (mandatory); arm_psa_UEID is used instead
- origination (recommended); arm_psa_origination is used instead

Later revisions of this documents might phase out those custom claims to be replaced by the EAT standard claims.

As noted, some fields must be at least 32 bytes long to provide sufficient cryptographic strength.

| Claim Key | Claim Description | Claim Name | CBOR Value Type |
|:------:|:---------:|:---------:|:-----------|
| -75000 | Profile Definition | arm_psa_profile_id | Text string |
| -75001 | Client ID | arm_psa_partition_id | Unsigned integer or Negative integer |
| -75002 | Security Lifecycle | arm_psa_security_lifecycle | Unsigned integer |
| -75003 | Implementation ID | arm_psa_implementation_id | Byte string (>=32 bytes) |
| -75004 | Boot Seed | arm_psa_boot_seed | Byte string (>=32 bytes) |
| -75005 | Hardware Version | arm_psa_hw_version | Text string |
| -75006 | Software Components | arm_psa_sw_components  | Array of map entries (compound map claim). See below for allowed key-values. |
| -75007 | No Software Measurements | arm_psa_no_sw_measurements  | Unsigned integer |
| -75008 | Auth Challenge | arm_psa_nonce  | Byte string |
| -75009 | Instance ID | arm_psa_UEID  | Byte string |
| -75010 | Verification Service Indicator | arm_psa_origination | Byte string |

When using the Software Components claim each key value MUST correspond to the following types:

 1. Text string (type)
 2. Byte string (measurement, >=32 bytes)
 3. Reserved
 4. Text string (version)
 5. Byte string (signer ID, >=32 bytes)
 6. Text string (measurement description)
 
# Example

The following example shows an attestation token that was produced 
for a device that has a single-stage bootloader, and an RTOS with a device 
management client. From a code point of view, the RTOS and the device
management client form a single binary. 

EC key using curve P-256 with:

- x: 0xdcf0d0f4bcd5e26a54ee36cad660d283d12abc5f7307de58689e77cd60452e75
- y: 0x8cbadb5fe9f89a7107e5a2e8ea44ec1b09b7da2a1a82a0252a4c1c26ee1ed7cf
- d: 0xc74670bcb7e85b3803efb428940492e73e3fe9d4f7b5a8ad5e480cbdbcb554c2

Key using COSE format (base64-encoded):

~~~
    pSJYIIy621/p+JpxB+Wi6OpE7BsJt9oqGoKgJSpMHCbuHtfPI1ggx0ZwvLfoWzgD77Q
    olASS5z4/6dT3taitXkgMvby1VMIBAiFYINzw0PS81eJqVO42ytZg0oPRKrxfcwfeWG
    ied81gRS51IAE=
~~~

Example of EAT token (base64-encoded):

~~~
    0oRDoQEmoFkCIqk6AAEk+1ggAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8
    6AAEk+lggAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh86AAEk/YSkAlggAA
    ECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8EZTMuMS40BVggAAECAwQFBgcIC
    QoLDA0ODxAREhMUFRYXGBkaGxwdHh8BYkJMpAJYIAABAgMEBQYHCAkKCwwNDg8QERIT
    FBUWFxgZGhscHR4fBGMxLjEFWCAAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0
    eHwFkUFJvVKQCWCAAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHwRjMS4wBV
    ggAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8BZEFSb1SkAlggAAECAwQFB
    gcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8EYzIuMgVYIAABAgMEBQYHCAkKCwwNDg8Q
    ERITFBUWFxgZGhscHR4fAWNBcHA6AAEk+RkwADoAAST/WCAAAQIDBAUGBwgJCgsMDQ4
    PEBESExQVFhcYGRobHB0eHzoAASUBbHBzYV92ZXJpZmllcjoAAST4IDoAASUAWCEBAA
    ECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh86AAEk93FQU0FfSW9UX1BST0ZJT
    EVfMVhAWIYFCO5+jMSOuoctu11pSlQrEyKtDVECPBlw30KfBlAcaDqVEIoMztCm6A4J
    ZvIr1j0cAFaXShG6My14d4f7Tw==
~~~

Same token using extended CBOR diagnostic format:

~~~
18(
  [
  / protected / h'a10126' / {
      \ alg \ 1: -7 \ ECDSA 256 \
    } / ,
  / unprotected / {},
  / payload / h'a93a000124fb5820000102030405060708090a0b0c0d0e0f1011121
  31415161718191a1b1c1d1e1f3a000124fa5820000102030405060708090a0b0c0d0e
  0f101112131415161718191a1b1c1d1e1f3a000124fd84a4025820000102030405060
  708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f0465332e312e34055820
  000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f01624
  24ca4025820000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c
  1d1e1f0463312e31055820000102030405060708090a0b0c0d0e0f101112131415161
  718191a1b1c1d1e1f016450526f54a4025820000102030405060708090a0b0c0d0e0f
  101112131415161718191a1b1c1d1e1f0463312e30055820000102030405060708090
  a0b0c0d0e0f101112131415161718191a1b1c1d1e1f016441526f54a4025820000102
  030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f0463322e320
  55820000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
  01634170703a000124f91930003a000124ff5820000102030405060708090a0b0c0d0
  e0f101112131415161718191a1b1c1d1e1f3a000125016c7073615f76657269666965
  723a000124f8203a00012500582101000102030405060708090a0b0c0d0e0f1011121
  31415161718191a1b1c1d1e1f3a000124f7715053415f496f545f50524f46494c455f
  31' / {
     / arm_psa_boot_seed / -75004: h'000102030405060708090a0b0c0d0e0f10
     1112131415161718191a1b1c1d1e1f',
     / arm_psa_implementation_id / -75003: h'000102030405060708090a0b0c
     0d0e0f101112131415161718191a1b1c1d1e1f',
     / arm_psa_sw_components / -75006: [
          {
            / measurement / 2: h'000102030405060708090a0b0c0d0e0f101112
            131415161718191a1b1c1d1e1f',
            / version / 4: "3.1.4",
            / signerID / 5: h'000102030405060708090a0b0c0d0e0f101112131
            415161718191a1b1c1d1e1f',
            / type / 1: "BL"
          },
          {
            / measurement / 2: h'000102030405060708090a0b0c0d0e0f101112
            131415161718191a1b1c1d1e1f',
            / version / 4: "1.1",
            / signerID / 5: h'000102030405060708090a0b0c0d0e0f101112131
            415161718191a1b1c1d1e1f',
            / type / 1: "PRoT"
          },
          {
            / measurement / 2: h'000102030405060708090a0b0c0d0e0f101112
            131415161718191a1b1c1d1e1f',
            / version / 4: "1.0",
            / signerID / 5: h'000102030405060708090a0b0c0d0e0f101112131
            415161718191a1b1c1d1e1f',
            / type / 1: "ARoT"
          },
          {
            / measurement / 2: h'000102030405060708090a0b0c0d0e0f101112
            131415161718191a1b1c1d1e1f',
            / version / 4: "2.2",
            / signerID / 5: h'000102030405060708090a0b0c0d0e0f101112131
            415161718191a1b1c1d1e1f',
            / type / 1: "App"
          }
        ],
      / arm_psa_security_lifecycle / -75002: 12288 / SECURED /,
      / arm_psa_nonce / -75008: h'000102030405060708090a0b0c0d0e0f10111
      2131415161718191a1b1c1d1e1f',
      / arm_psa_origination / -75010: "psa_verifier",
      / arm_psa_partition_id / -75001: -1,
      / arm_psa_UEID / -75009: h'01000102030405060708090a0b0c0d0e0f1011
      12131415161718191a1b1c1d1e1f',
      / arm_psa_profile_id / -75000: "PSA_IoT_PROFILE_1"
    }),
    } / ,
  / signature / h'58860508ee7e8cc48eba872dbb5d694a542b1322ad0d51023c197
  0df429f06501c683a95108a0cced0a6e80e0966f22bd63d1c0056974a11ba332d7877
  87fb4f'
  ]
)
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
  Security Theory LLC
  lgl@securitytheory.com
~~~

~~~
* Tamas Ban
  Arm Limited
  Tamas.Ban@arm.com
~~~

# Reference Implementation 

Trusted Firmware M (TF-M) {{TF-M}} is the name of the open source project that provides 
a reference implementation of PSA APIs and an SPM, created for the latest Arm v8-M microcontrollers
with TrustZone technology. TF-M provides foundational firmware components that silicon 
manufacturers and OEMs can build on (including trusted boot, secure device initialisation 
and secure function invocation).

