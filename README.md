# MWE-NEDNSProxyProvider
This repository contains a Minimal Working Example (MWE) project prepared for the Apple Developer Technical Support team. It demonstrates a regression in NEDNSProxyProvider behaviour observed in iOS 18.4.1


- No additional configuration, MDM, or device supervision is required.
- The sample project runs out of the box.

### Steps to Reproduce

1. Run the sample project on two physical devices:
2. One running iOS 18.3.2 (or earlier)
3. One running iOS 18.4.1 (or newer)
4. On both devices, launch a browser (e.g., Safari or Chrome).
5. Attempt to perform any search or load a webpage.

### Expected Behavior

Both devices should maintain internet connectivity and successfully resolve DNS queries via the DNS proxy.

### Actual Behavior
The device running iOS 18.3.2 works as expected.
The device running iOS 18.4.1 or newer loses connectivity, and DNS resolution fails.
