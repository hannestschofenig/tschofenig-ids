---
title: Report from the Internet of Things (IoT) Software Update Workshop (IoTSU) Workshop 2016
abbrev: IOTSI
docname: draft-iab-iotsu-workshop-00.txt
category: info
date: 2016-09-25

ipr: trust200902
area:
workgroup: 
keyword: Internet-Draft, Security, Firmware Updates, Software Updates, Internet of Things

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
       email: hannes.tschofenig@arm.com
 -
       ins: S. Farrell
       name: Stephen Farrell
       email: stephen.farrell@cs.tcd.ie

normative:
 
informative:
  RFC6561: 
  RFC4108:
  RFC7406: 
  BS14:
    title: The Internet of Things Is Wildly Insecure And Often Unpatchable
    author: 
      - ins: B. Schneier
    date: January 2014
    target: https://www.schneier.com/essays/archives/2014/01/the_internet_of_thin.html
  FTC:
    title: FTC Report on Internet of Things Urges Companies to Adopt Best Practices to Address Consumer Privacy and Security Risks
    author: 
      org: Federal Trade Commission
    date: January 2015
    target: https://www.ftc.gov/news-events/press-releases/2015/01/ftc-report-internet-things-urges-companies-adopt-best-practices
  WP29:
    title: Opinion 8/2014 on the on Recent Developments on the Internet of Things
    author: 
      org: Article 29 Data Protection Working Party
    date: September 2014
    target: http://ec.europa.eu/justice/data-protection/article-29/documentation/opinion-recommendation/files/2014/wp223_en.pdf
  OS14:
    title: Too Many Cooks – Exploiting the Internet-of-TR-069-Things
    author: 
      - ins: L. Oppenheim
      - ins: S. Tal
    date: December 2014
    target: https://www.schneier.com/essays/archives/2014/01/the_internet_of_thin.html
  foo:
    title: Paper about on-device malware analysis
    author: 
      - ins: J. Doe
    date: December 2014
    target: https://www.schneier.com/essays/archives/2014/01/the_internet_of_thin.html
  BB14:
    title: Winks Outage Shows Us How Frustrating Smart Homes Could Be
    author: 
      - ins: B. Barrett
    date: April 2014
    target: http://www.wired.com/2015/04/smart-home-headaches/
  IoTSU:
    title: Internet of Things Software Update Workshop (IoTSU)
    author: 
      org: IAB
    date: June 2016
    target: https://www.iab.org/activities/workshops/iotsu/
  LittlePrinter: 
    title: The future of Little Printer
    author: 
      org: Berg
    date: September 2014
    target: http://littleprinterblog.tumblr.com/post/97047976103/the-future-of-little-printer
  NEA: 
    title: Network Endpoint Assessment (nea) (Concluded Working Group)
    author: 
      org: IETF
    date: 2016
    target: https://datatracker.ietf.org/wg/nea/charter/
  HP-Firmware: 
    title: HP detonates its timebomb - printers stop accepting third party ink en masse
    author: 
      org: BoingBoing
    date: September 2016
    target: http://boingboing.net/2016/09/19/hp-detonates-its-timebomb-pri.html
  courgette: 
    title: Software Updates - Courgette
    author: 
      org: Google
    date: September 2016
    target: https://www.chromium.org/developers/design-documents/software-updates-courgette

  RAPPOR: 
    title: RAPPOR
    author: 
       - ins: U. Erlingsson
       - ins: V. Pihur
       - ins: A. Korolova
    date: Jul 2014
    target: https://github.com/google/rappor

  bsdiff: 
    title: Binary diff/patch utility
    author: 
       - ins: C. Percival
    date: September 2016
    target: http://www.daemonology.net/bsdiff/

  hashsig: 
    title: Hash based signatures
    author: 
       - ins: A. Langley
    date: 18 July 2013
    target: https://www.imperialviolet.org/2013/07/18/hashsig.html

  housley-cms-mts-hash-sig: 
    title: Use of the Hash-based Merkle Tree Signature (MTS) Algorithm in the Cryptographic Message Syntax (CMS)
    author: 
       - ins: R. Housley
    date: 21 March 2016
    target: https://tools.ietf.org/html/draft-housley-cms-mts-hash-sig-04

  OS-Support: 
    title: Providing OS Support for Wireless Sensor Networks - Challenges and Approaches
    author: 
       - ins: W. Dong
       - ins: C. Chen
       - ins: X. Liu
       - ins: J. Bu
    date:  May 2010 
    target: http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=5462978
  
--- abstract

This document provides a summary of the 'Workshop on Internet of Things (IoT) Software Update (IOTSU)' {{IoTSU}}, which took place at the at Trinity College Dublin, Ireland on the 13th and 14th of June, 2016. The main goal of the workshop was to foster a discussion on requirements, challenges and solutions for bringing software and firmware updates to IoT devices. 

This report summarizes the discussions and lists recommendations to the standards community. The views and positions in this report are those of the workshop participants and do not necessarily reflect those of the authors and the Internet Architecture Board (IAB), which organized the workshop.

--- middle

# Introduction

The Internet Architecture Board (IAB) holds occasional workshops designed to consider long-term issues and strategies for the Internet, and to suggest future directions for the Internet architecture. The investigated topics often require coordinated efforts of many organizations and industry bodies to improve an identified problem. One of the targets of the workshops is to establish communication between relevant organisations, companies and universities, specially when the topics are out of the scope for the Internet Engineering Task Force (IETF). This long-term planning function of the IAB is complementary to the ongoing engineering efforts performed by working groups of the IETF. 

In his essay 'The Internet of Things Is Wildly Insecure And Often Unpatchable' {{BS14}} Bruce Schneier expressed concerns about the status of software/firmware updates for Internet of Things (IoT) devices. IoT devices, which have a reputation for being insecure already at the time when they are manufactured, are often expected to stay active in the field for 10+ years and operate unattended with Internet connectivity.

Incorporating a software update mechanism to fix vulnerabilities, to update configuration settings as well as adding new functionality is recommended by security experts but there are challenges when using software updates, as the FTC staff report on Internet of Things – Privacy &amp; Security in a Connected World {{FTC}} and the Article 29 Working Party Opinion 8/2014 on the on Recent Developments on the Internet of Things {{WP29}} express. Even designing a basic software/firmware update functionality is challenging due to the constrained nature of IoT devices. Implementations of these software update mechanisms may suffer from buffer overflow vulnerabilities, see for example {{OS14}}, and operational challenges may also surface, as an expired certificate in a hub device {{BB14}} demonstrates. Additionally, there are various problems with privacy, lack of incentives to distribute software updates along the value chains, and questions about who should be able to update devices, and when, e.g. at or after the end-of-life of a product or component.

There are various (often proprietary) software update mechanisms in use today and the functionality of those varies significantly with the envisioned use of the IoT devices. More powerful IoT devices, such as those running general purpose operating systems (like embedded Linux), make use of sophisticated software update mechanisms known from the desktop and the mobile world. This workshop focused on more constrained IoT devices that often run dedicated real-time operating systems or potentially no operating system at all. 

There is a real risk that many IoT devices will be shipped without a solid software/firmware update mechanism in place. Ideally, IoT software developers and product designers should be able to integrate a standardized mechanism that has been experienced substantial review and where the documentation is available to the public. 

Hence, the IAB decided to organize a workshop to reach out to relevant stakeholders to explore the state-of-the-art and to identify requirements and gaps. In particular, the call for position papers asked for 

  * Protocol mechanisms for distributing software updates.
  * Mechanisms for securing software updates.
  * Meta-data about software / firmware packages.
  * Implications of operating system and hardware design on the software update mechanisms.
  * Installation of software updates (in context of software and hardware security of IoT devices).
  * Privacy implications of software update mechanisms.
  * Implications of device ownership and control for software update.

The rest of the document is organized as follows: {{terminology}} introduces terminology useful in this context as discussed at the workshop... 

# Terminology {#terminology}

Device Classes
: IoT devices come in various configurations (such as size of RAM, or size of flash memory). With these configurations devices are limited in what they can support in terms of operating system features, cryptographic algorithms, and protocol stacks. For this reason, the group differentiated two types of classes, namely ARM Cortex A-class (or Intel Atom) and Cortex M-class (or Intel Quark) type of devices. A-class devices are equipped with powerful processors typically found in setup boxes and home gateway. The Raspberry Pi is an example of a A-class device, which is able to run a regular desktop operating system, such as Linux. There are differences between the Intel and the ARM-based CPUs in terms of uCode and who is able to update a BIOS (if available) and the uCode. A detailed discussion of these hardware architectural differences were, however, outside the scope of the workshop.

Software Update vs. Firmware Update
: Based on the device classes it was observed that regular operating systems come with a sophisticated software update mechanisms (such as rpm or Pacman) that make use of the operating system to install, and run each application in a compartmentalized fashion. Firmware updates typically do not provide such a fine-grained granularity for software updates and instead distribute the entire binary image, which consists of the (often minimalistic) operating system and all applications. While the distinction between what A-class and M-class devices typically use get more fuzzy over time, most M-class devices use firmware updates and A-class devices use a combination of firmware and software updates (with firmware updates being less frequent operations). 
   
Device Reboot vs. Hitless Update
: After a firmware or a software image has been distributed the question arises whether the device has to be restarted or not. For many desktop, smart phones and tablets new software updates do not require a restart when new applications are installed while changes to the underlying operating system often require a restart. For embedded devices a firmware update often requires a device reboot since it is also the easiest way to get the device into a clean state. A hitless update refers to a firmware or software update that does not require a restart and is frequently used in environments where the downtime has to be minimized (with the expense of added complexity), such as networking infrastructure likes routers or switches.

# Requirements {#requirements} 

 The group discussed the requirements and several of the requirements raised further questions. 

   * The is a need to be support partial (differential) firmware updates, not just entire image. This may mean that techniques like bsdiff {{bsdiff}} and courgette {{courgette}} are used but might also devices supporting download of applications and libraries alone. The latter feature may require dynamic linking and position independent code. 

   * The support for devices with multiple microcontrolers implies that one microcontroller is responsible for interacting with the update service and then dispatches software images to the attached microcontrollers within its local realm. 

   * Support devices with multiple owners/stakeholders where the question arises about who is authorized to push a firmware/software update.

   * How important are dynamic linkers for low-end IoT devices? Some operating systems used with M-class devices, such as Contiki, provide support for a dynamic linker according to {{OS-Support}}. This could help to minimize the amount of code transmitted during code updates since only the modified application or library needs to be transmitted.    
   
   * Should position independent code be recommended for low-end IoT devices? 

   * How should dependencies among various software updates been described as meta-data? The dependencies may include information about the hardware platform and configuration the software runs on as well as other software components running on a system.   

   * Should digital signatures and encryption for software updates be recommended as a best current practice? This question also raised the question about the use of symmetric key cryptography since not all low end IoT devices are indeed using asymmetric crypto.  

   * Should a firmware update mechanism support multiple signatures of firmware images? Is an IoT device expected to verify the different types of signatures to verify the different sources or is this rather a service provided by some non-constrained device? This raises the question about who the IoT device should trust and whether transitive trust is accepted for some types of devices? Multiple signatures can come in two different flavours, namely (a) a single firmware image may be signed by multiple different parties or (b) a software image may contain of libraries that are each signed by their developers. In the former case one could imagine an environment where an OEM signs the software it cares but then the software is again signed by the enterprise that approves the distribution within the company. Are there different apps that are allowed to run on the device? Or only apps from the OEM?  If the device is a "closed" device that only supports/runs SW from the OEM then a single signature may be OK.  In an "open" system, 3rd party apps may require support of multiple signatures. Other examples include regulatory signatures. Medical device SW may be signed as approved by a regulator.

  * Minimize device/service downtime due to update processing. Strive for zero device downtime, or strive for "no inappropriate" device downtime. This means no downtime that impacts the user/operation of the device.  Larger devices with appropriate system resources support "live updates" that minimize device downtime. This needs to address both when you start the upgrade and when you finish it (how long it takes). What is "downtime" also depends on the use case.  With a smart light bulb, the device could be up if the light is still on, even if some of the advanced services are unable for a short time.  The device can download, validate software and prepare for updates without impacting the user.  This minimizes downtime to the reboot time. Whether an update can be done without rebooting the device (hitless update) depends on the software being installed, on the OS architecture, and potentially even on the hardware architecture. Is this an issue of larger A-class devices or should this functionality also be supported by M-class devices? 

  * Requirement for minimizing user interaction. Do not disrupt other activity (e.g., car should not distract the driver).

  * Firmware update signing key requirements. Since devices have a rather long lifetime there has to be a way to change the signing key during the lifetime of the device.  
  
  * Requirements during manufacturing. During the manufacturing process there is no desire to depend on Internet connectivity to stall the factory. In one presented solution HTTP with the caching capabilities was used in the factory to avoid creating such a dependency. In addition to the Internet connectivity requirement there is also the security requirement; it should not be possible for a factory worker to steal secrets during the manufacturing process. There are typically two factories involved, first the factory that produces microcontrollers and other components. The second factory produces the complete product, such as a fridge. This fridge contains many of the components previously manufactured. Hence, the firmware of components produced in the first stage may be 6 month old when the fridge leaves the factory. One does not want to install a firmware update when the fridge boots the first time. For that time the firmware update happens already at the end of the manufacturing process. 

  * Should devices have a recovery procedure when the device gets compromised? How is the compromise detected?

  * Time synchronization was seen as a chicken-and-egg problem since relying synchronized clocks is difficult for many IoT-based deployments. Participants argued that there is rarely a checking of the expiry of certificates and that certification revocation checking is also rarely done. 
  
  * How do devices learn about a firmware update? Push or Pull? What should be required functionality for a firmware update protocol?  

  * We need to find out whether the software update was successful. Breaking the device is sometimes hard to determine. In one discussed solution the bootloader analyses the performance of the running image to determine which image to run (rather than just verifying the integrity of the received image). One of the key criteria is that the  updated system is able to make a connection to the device management/software update infrastructure. As long as it is able to talk to the cloud it can receive another update. As alternative perspective the argument was made that one needs to have a way to update the system without have the full system running.
   
  * Authentication and integrity protection of the firmware distribution must be supported, at a minimum. The requirement for authentication primarily referred to an IoT device receiving a firmware update to authenticate the source of that firmware image. There was also a discussion about the need to allow the server-/infrastructure-side to authenticate the IoT device before distributing an update and questions about the identifier used for such an authentication action was rasied. The idea to re-use MAC addresses was raised and lead to concerns about the possible privacy implications. 
         
  * Gateway requirements. In some deployments gateways terminate the IP-based protocol communication and use non-IP to communicate with other microcontrollers internally within a systems, such as within a car. The gateway is the end point of the IP communication. The group itself had a mixed feelings about the use of gateways and the use of IP communication to every microcontrollers. Participants argued that there is a lack of awareness of IPv6 header compression (with the 6lowpan standards) and how beneficial the use of IPv6 in those environments is to lower the complexity of the overall system. 
  
  * There is also a need for secure storage.  This includes at least the need to protect the integrity of the public key of the update service on the device.
  
Which of these are nice to have? Which are required?
Not all of these are required to achieve improvement. What are most important?

Among the participants there was consensus that supporting signatures (for integrity and authentication) of the firmware image itself and the need for partial updates was seen as important. 

There were, however, also concerns regarding the performance implications since certain device categories may not utilize public key cryptography at all and hence only a symmetric key approach seems viable. This aspect raised concerns and trigger a discussions around the use of device management infrastructure, which similar to Kerberos, manages keys and distributes them to the appropriate parties. As such, in this set-up there is a unique key share with the key distribution center but for use with specific services (such as a software update service) a fresh and unique secret would be distributed. 

In addition to the requirements for the end devices there are also infrastructure-related requirements. The infrastructure may consist of servers in the local network and/or various servers deployed on the Internet. It may also consist of some application layer gateways. 

  * Local server acts for neighbouring nodes. For example, in a vehicle one dedicated entity can process all firmware updates and redistributes them to interconnected microcontrollers. 
  * Infrastructure may perform some digital signature checks on behalf of the devices (e.g., certificate revocation checking)
  * Use multicast to transmit same update to many similar devices
  * Hide complexity associated with NAT and Firewalls from the device
  * Since many IoT devices will not be (directly) connected to the internet, but only through a gateway there is the need to develop a software / firmware update mechanism that works in such environments where no end-to-end Internet connectivity exists and where connectivity may be intermittent. 

A firmware update mechanism may demand the ability to identify devices. Different design approaches are possible. 

  * In an extreme form in one case the decision about updating a device is made by the infrastructure based on the unique device identification. The operator of the firmware update infrastructure knows about the hardware and software requirements for the IoT devices, knows about the policy for updating the device, etc. The device itself is provisioned with credentials so that it can verify a firmware update coming from an authorized device. 
  
  * In another extreme the device has knowledge about the software and hardware configuration and possible dependencies. It consults software repositories to obtain those software packages that are most appropriate. Verifying the authenticity of the software packages/firmware images will still be required. 
  
Hence, in some deployed software update mechanisms there is no desire for the device to be identified beyond the need to exchange information about most recent software versions. For other devices, it is important to identify the device itself in order to provide the appropriate firmware image/software packages.  

Related to device identification various privacy concerns arise, such as the need to determine what information is provided to whom and what this information is used for. For a certain class of IoT devices where there is a close relationship to a user the privacy concerns may be higher than for devices where such a relationship does not exist (e.g., a sensor measuring concrete). The software / firmware update mechanism should, however, not make the privacy situation of IoT devices worse. The proposal from the group was to introduce a minimal requirement of not sending any new identifiers over an unencrypted channel as part of SW/FW update protocol.  


# Performance

   * Not just sending updates to each device individually 
   * Differential updates, examples are bsdiff {{bsdiff}} and courgette {{courgette}}
   * firmware update consumes a lot of energy
   * requires sufficient amount of flash for storing a backup image
 

# Authorizing a Software / Firmware Update {#authz} 

  * Who can accept or reject an update? Is it the owner of the device, or the user or both? The user may not necessarily be the owner. 
  * With products that fall under a regulatory structure, such as healthcare, you don't want firmware other than what has been accredited.  
  * In some cases it will be very difficult for a firmware update system to communicate to users that an update is available. This requires tracking the device (and the status with regards to the installed firmware/software and some knowledge about the user itself). 
  * Furthermore, not all updates are the same. Security updates may need to be treated differently than feature updates. Lack of updates due to end of life / end of support for a given product may again be treated differently. More complex questions arise when considering the impact of the update (or the lack of updating) impacts other devices, other persons, or the public in general? 
  * As such, with many IoT devices there are many stakeholders contributing to the end product and ensuring that security vulnerabilities are fixed and software/firmware updates are communicated through the value chain is known to be difficult. 
  * Some people don't want updates; it's good enough as it is working and users are worried about unwanted changes to their products, such as the recent HP printer firmware update pushed in March 2016 indicates {{HP-Firmware}}.
  * What about forgotten devices? It does not mean that such a device is not part of some critical system.  
 
  * Can we determine whether the update impacts other devices in the IoT? Updates to one device can have unintended impact on other devices that depend on it. This can have cascading effects if we are not careful.  Changing the output of a sensor can have cascading impacts. 
 
  * How should end-of-life, or end-of-features be treated? Devices are often deployed for 10+ years (or even longer in some verticals). Companies may not want to support  software and services for such an extended period of time. In some cases they may not be willing to do so, for example due to a change in business strategies caused by a merger. In yet other cases a company may have gone bankrupt. While there are many legal, ethical, and business related questions can we technically enabled transfer of device service to another provider? Is the release of code, as it was done with the Little Printer manufactured and developed by a company called Berg {{LittlePrinter}}. While the community took over the support this can hardly be assumed in all cases. Just releasing the source code of a product does not necessarily trigger others to work on the code, to fix bugs and to potentially even maintain a service. Nevertheless, escrowing code so that the community can take it over if a company fails is one possible option. The situation gets more complex when the device used security mechanisms to ensure that only selected parties are allowed to update the device. In this case, the private signing key needs to be made available as well, which could introduce security problems for already deployed software. In the best case it changes assumptions made about the trust model and about who can submit updates. 

 * How should deployed devices behave when they are end-of-life and the support ends. Many of them may still function normally, others may stop contacting cloud infrastructure services. Some products are probably expected to fail safely, similarly to a smoke alarm that makes a loud noise when the battery becomes empty. Cell phones without a contract can, in some countries, still be used for emergency services (although at the expense of the society due to untraceable hoax calls), as discussed in RFC 7406 {{RFC7406}}. 

The recommendation that can be provided to companies is to think about the end-of-life, end-of-support scenarios ahead of time and plan for those. While companies rarely want to consider what happens if their business fails it is still legitimate to also consider the scenario where they are hugely successful and want to evolve their products line to support instead of supporting previously sold products forever. Maybe there is also a value in a subscription-based model where product and device support is only provided as long as the subscription is paid. Without a subscription the product is deactivated and cannot pose a threat to the Internet at large.   


# Incentives

The group has been discussing how to create incentives for companies to ship software updates, which is particularly important for products that will be deployed in the market for a long time. It is also further complicated by complex value chains.  

  * Companies shipping software updates benefit from improved security; for end-users, updates break things. The negative customer experience is due to the service interruptions during the update but can also be bad experience  from what happens after the update, such as a feature that is not available anymore, or that a "bug" that another service has relied on was fixed.

  * In the open source community public shaming works since the community is open to feedback. The problem is when changes are available, just not applied, since there is not necessarily an entity that pushes patches out.

  * There does not seem to be a regulatory requirement to report vulnerabilities, similar to data breach notification laws. 
  
  * Subscription model was device management was suggested so that companies providing the service an economic interest in keeping devices online (and updated for that). Example: Electric Imp

# Measurements and Analysis

From a security point of view it is important to know what devices are out there and what version of software they run. As such, in addition to the firmware update mechanism companies, like Electric Imp, have been offering device management solutions that allow OEMs to keep track of their devices. Tracking these devices and their status is still challenging since some devices are only connect irregularly or are only turned on when needed (such as a hockey alarm that is only turned on before a match). 

Various stakeholders are interested to know information about deployed IoT devices. For example, 

   * Manufacturers and other players in the supply chain are interested to know what devices are out there, how many have been sold, what devices are out there but have not been sold. This would help to understand what firmware versions still to support.  How should a device behave when it is running out-of-date software. Example with smoke alarm was mentioned. Are devices supposed to stop working?
   * enterprises and network operators, for example in a building infrastructure, for risk assessment. 
   * regulators and law makers for evaluating the effectiveness of cyber security laws.
   * users, owners, and customers. This group may want to know what devices are installed over a longer period of time, what softare/firmware version is the device running, what is uptime of each of these devices, what types of faults have occured, etc. Forgotten devices may pose problems, particularly if they behave disfunctional
   * researchers for doing analysis on the status of the Internet ecosystem (such as what protocols are being used, how much data IoT devices generate, etc. 


There is some invasiveness in the approach of building these measurements. The challenge was put forward to find ways to create measurements infrastructure that is privacy preserving. Arnar Birgisson noted that there are privacy-preserving statistical techniques, such as RAPPOR {{RAPPOR}}, and Ned Smith added that the Enhanced Privacy ID (EPID) may play a role in maintaining anonymity of the IoT devices. 

# Firmware Distribution in Mesh Networks

TBD. 


# Quarantine Compromised Devices

A system that allows to single out a device, which shows faulty behavior or has been compromised, and to shut it down has been considered useful. 

Prior work in the IETF on Network Endpoint Assessment (NEA) {{NEA}} allowed to assess the "posture" of devices. Posture refers to the hardware or software configuration of a device and may
include knowledge that software installed is up-to-date. 

The obtained information can then be used by the network infrastructure to create a quarantine network around the device. Devices in isolation are subject to software updates. 

Also the concept of an ISP to send "signals" to the customer's home network has been since many network operators may not be interested to offer this functionality. The document that describes functionality for an ISP to inform customers about botnets can be found at RFC 6561 {{RFC6561}}. 

Neither RFC 6561 nor NEA has found widespread deployment. Whether these mechanisms are more successful in the IoT environment has yet to be studied. 

There is also a desire to explore mechanisms on the device that shuts down the device itself. An example of such an approach has been studied in {{foo}}.  

The conclusion of the discussion at the workshop itself was that there is some interest to identify and stop misbehaving devices but the actual solution mechanisms are unclear. 

# Security Considerations

This document summarizes an IAB workshop on software/firmware updates and the entire content is therefore security related. Standardizing and deploying a software/firmware update mechanism for use with IoT devices will help to fix security vulnerabilities. 

The IETF has published a specification that uses the Cryptographic Message Syntax (CMS) to protect firmware packages, as described in RFC 4108 {{RFC4108}}, which also contains meta-data to describe the firmware image itself. During the workshop the question was raised whether a solution is needed that is post-quantum secure. A post-quantum cryptosystem is a system that is secure against quantum computers that have more than a trivial number of quantum bits. It is open to conjecture whether it is feasible to build such a machine but RSA, DSA, and ECDSA are not post-quantum secure. This may require introducing technologies like the Hash-based Merkle Tree Signature (MTS) {{housley-cms-mts-hash-sig}}, which was presented and discussed at the workshop. The downside of such a solution is the fairly large signature, i.e., depending on the parameters a signature could easily have a size of 20-30KiB {{hashsig}}. 


# Next Steps

The majority of the workshop participants agreed that the following items present the most important next steps: 

   * Find an agreement on the scope of a standardized software/firmware update mechanism. 

   * Investigate solutions to install updates with no operation interruption as well as ways to distribute software updates without disrupting network operations (specifically in low-power wireless networks), including the development of a multicast transfer mechanism (with appropriate security).

   * A way to transfer authority for updates, particularly considering end-of-life, will be key for an update mechanism. 

   * We need proof-of-concepts showing software/firmware updates for constrained devices on different IoT operating system architectures.

# IANA Considerations

This document does not contain any requests to IANA. 

# Acknowledgements

We would like to thank all paper authors and participants for their contributions. The IoTSU workshop is co-sponsored by the Internet Architecture Board and the Science Foundation Ireland funded CONNECT Centre for future networks and communications. The programme committee would like to express our thanks to Comcast for sponsoring the social event.


# Appendix A: Program Committee

This workshop was organized by the IAB with the help of the following individuals: Stephen Farrell, Arnar Birgisson, Ned Smith, Jari Arkko, Carsten Bormann, Hannes Tschofenig, Robert Sparks, and Russ Housley.

# Appendix B: Accepted Position Papers

  * R. Housley, 'Position Paper for Internet of Things Software Update Workshop (IoTSU)'
  * D. Thomas and A. Beresford, 'Incentivising software updates'
  * L. Zappaterra and E. Dijk, Software Updates for Wireless Connected Lighting Systems: requirements, challenges and recommendations'
  * M. Orehek and A. Zugenmaier, 'Updates in IoT are more than just one iota'
  * D. Plonka and E. Boschi, 'The Internet of Things Old and Unmanaged'
  * D. Bosschaert, 'Using OSGi for an extensible, updatable and future proof IoT'
  * A. Padilla, E. Baccelli, T. Eichinger and K. Schleiser, 'The Future of IoT Software Must be Updated'
  * T. Hardie, 'Software Update in a multi-system Internet of Things'
  * R. Sparks and B. Campbell, 'Avoiding the Obsolete-Thing Event Horizon'
  * J. Karkov, 'SW update for Long lived products'
  * S. Farrell, 'Some Software Update Requirements'
  * S. Chakrabarti, 'Internet Of Things Software Update Challenges: Ownership, Software Security & Services'
  * M. Kovatsch, A. Scholz, and J. Hund, 'Why Software Updates Are More Than a Security Issue'
  * A. Grau, 'Secure Software Updates for IoT Devices'
  * Birr-Pixton, Electric Imp’s experiences of upgrading half a million embedded devices'
  * Y. Zhang, J. Yin, C. Groves, and M. Patel, 'oneM2M device management and software/firmware update'
  * E. Smith, M. Stitt, R. Ensink, and K. Jager, 'User Experience (UX) Centric IoT Software Update'
  * J.-P. Fassino, E.A. Moktad, J.-M. Brun, 'Secure Firmware Update in Schneider Electric IOT-enabled offers'
  * M. Orehek, 'Summary of existing firmware update strategies for deeply embedded systems'
  * N. Smith, 'Toward A Common Modeling Standard for Software Update and IoT Objects'
  * S. Schmidt, M. Tausig, M. Hudler, and G. Simhandl, 'Secure Firmware Update Over the Air in the Internet of Things Focusing on Flexibility and Feasibility'
  * A. Adomnicai, J. Fournier, L. Masson, and A. Tria, 'How careful should we be when implementing cryptography for software update mechanisms in the IoT?'
  * V. Prevelakis and H. Hamad, 'Controlling Change via Policy Contracts'
  * H. Birkholz, N. Cam-Winget and C. Bormann, 'IoT Software Updates need Security Automation'
  * R. Bisewski, 'Comparative Analysis of Distributed Repository Update Methodology and How CoAP-like Update Methods Could Alleviate Internet Strain for Devices that
Constitute the Internet of Things'
  * J. Arrko, 'Architectural Considerations with Smart Objects and Software Updates'
  * J. Jimenez and M. Ocak, 'Software Update Experiences for IoT'
  * H. Tschofenig, 'Software and Firmware Updates with the OMA LWM2M Protocol'

# Appendix C: List of Participants

  * Arnar Birgisson, Google
  * Alan Grau, IconLabs
  * Alexandre Adomnicai
  * Alf Zugenmaier, Munich University of Applied Science
  * Ben Campbell, Oracle
  * Carsten Bormann, TZI University Bremen
  * Daniel Thomas, University of Cambridge
  * David Bosschaert
  * David Malone
  * David Plonka
  * Doug Leith
  * Emmanuel Baccelli, Inria
  * Eric Smith, SpinDance
  * Jean-Philippe Fassino, Schneider Electric
  * Jørgen Karkov, Grundfos
  * Joseph Birr-Pixton, Electric Imp
  * Kaspar Schleiser, Freie Universität Berlin
  * Luca Zappaterra, Philips Lighting Research
  * Martin Orehek, Munich University of Applied Science
  * Mathias Tausig, FH Campus Wien
  * Matthias Kovatsch, Siemens
  * Milan Patel, Huawei
  * Ned Smith, Intel
  * Robert Ensink, SpinDance
  * Robert Sparks, Oracle
  * Russ Housley, Vigilsec
  * Samita Chakrabarti, Ericsson
  * Stephen Farrell, Trinity College Dublin
  * Vassilis Prevelakis, TU Braunschweig
  * Hannes Tschofenig, ARM Ltd. 
