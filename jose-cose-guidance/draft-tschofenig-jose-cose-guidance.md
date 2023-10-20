---
title: Guidance for COSE and JOSE Protocol Designers and Implementers

abbrev: COSE/JOSE Guidance
docname: draft-tschofenig-jose-cose-guidance-00
category: bcp

ipr: trust200902
area: Security
workgroup: JOSE
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
      email: hannes.tschofenig@siemens.com
      org:

 -
      ins: L. Hazlewood
      name: Les Hazlewood
      email:  lhazlewood@gmail.com
      org:

normative:
  RFC2119:
informative:
  I-D.tschofenig-rats-psa-token:

--- abstract

JSON Object Signing and Encryption (JOSE) and  CBOR Object Signing
and Encryption (COSE) are two widely used security wrappers, which
have been developed in the IETF and have intentionally been kept
in sync.

This document provides guidance for protocol designers developing
extensions for JOSE/COSE and for implementers of JOSE/COSE libraries.
Developers of application using JSON and/or JOSE should also read
this document but are realistically more focused on the documentation
offered by the library they are using.

--- middle

#  Introduction

JSON Object Signing and Encryption (JOSE) has initially been designed
to offer provide a security wrapper for access tokens used by the
OAuth protocol. The larger applicability of a standard for describing
a security-related meta-data was, however, immediately recognized.
Today, JOSE is in wide spread use.

With the development of CBOR a binary encoding format was developed
to address use cases where JSON was too verbose. A security wrapper
that uses CBOR-based encoding was needed and CBOR Object Signing
and Encryption (COSE) was standardized.

The JOSE and COSE specifications have intentionally been kept in
sync since protocols and payloads today are often described in
the Concise Data Definition Language (CDDL) and serialized to
either JOSE or COSE thereby making them attractive to developers
from the web and the embedded world at the same time. Due to the
similarity of the designs, the guidance provided in this document
is therefore applicable to JOSE and COSE.

Unfortunately, some practices cause challenges from a security
point of view and this document captures those. We hope that this
document helps to design better extensions for JOSE/COSE and to
make the life of developers easier.

The document is structured as follows. {{kid}} describes the
challenges with key identification. Future versions of this
document will add further challenges. {{guidance}} then offers
guidance for how to create better designs for JOSE/COSE.

# Terminology and Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

#  Key Identification {#kid}

The security wrappers in JOSE and COSE use a simple design, at least
for the basic functionality like digital signatures and MACs for a
single recipient.

The structure is as follows:

 - A header, which is split into a protected and unprotected parameters.
 - An optional payload. It is optional because the payload may be detached.
 This is the payload we want to protect. In many applications this
 payload is a JSON-based payload (in case of JOSE) or a CBOR-encoded
 payload (in case of COSE). Various IETF specifications exist that
 standardize the content of these payloads.
 - A digital signature, a tag (for a MAC), or a ciphertext (for encryption).

The purpose of the header is to provide instructions for the protection of
the payload, including

* algorithm information used to provide protection of the payload,
* the identification of the key to verify the digital signature, MAC, or
encryption,
* X.509 certificates and certificate chains,
* countersignature.

Although the layering is quite simple with the header providing the information
to provide protection of the payload, some specifications and applications
started to place information for key identification inside the payload. This
approach destroys the clear layering.

Additionally, it forces a JOSE/COSE parser to defer security processing of the
payload to a later point in time and to look inside the payload to find the
appropriate keying material to subsequently verify the payload.

There is no need for such design since there are existing header parameters
available to store the necessary information. If those headers are insufficient,
then it is always possible to define new header parameter to convey this informtion.
This approach also simplifies libraries since they do not need to understand
the payload content to fetch the correct information.

Finally, an easy transition from a system using digital signatures over
payloads to encrypted payloads is not possible since information needed
for key look-up are found in the encrypted payload. A re-design would
therefore be required.

# Guidance {#guidance}

We RECOMMEND that protocol designers and implementers use the
available header parameter for key identification. If the standardized
parameters are insufficient, new header parameters can be defined.
Re-using existing header parameters will improve interoperability
because there are a limited number of cases on how to select a key.

Information that is needed for determining the keying material needed
to cryptographically verify the protected payload MUST be placed
into the header of the JOSE/COSE security wrapper.

#  IANA Considerations

This document does not make requests to IANA.

#  Security Considerations

This specification makes security recommendations for the
JOSE/COSE specification suite. Therefore, it is entirely
about security.
--- back

# Acknowledgments

TBD: Add your name here.
