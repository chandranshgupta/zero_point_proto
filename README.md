# 👻 Stealth Chat (HackSecure 2026 Prototype)

> **⚠️ HACKATHON PROTOTYPE NOTICE ⚠️**
> This repository contains an **incomplete, proof-of-concept prototype** developed specifically for the **HackSecure 2026 (NIT Hamirpur x MeitY)** hackathon. 
> 
> It is a demonstration of localized cryptographic routing and ephemeral state management. **It is NOT a production-ready application.** The current build utilizes a trusted local WebSocket relay for demonstration purposes and does not yet include automated forward secrecy (Double Ratchet) or offline mesh routing. Do not use this for sensitive, real-world communication.

## The Mission: Absolute Anonymity
Standard chat applications are data miners disguised as utilities. Even when payloads are encrypted, centralized infrastructure hoards the metadata—the *who*, *when*, and *where*. 

Stealth Chat is an exploration into absolute digital sovereignty. We built an ephemeral messaging environment that bypasses centralized trust entirely, focusing strictly on actionable application over abstract theory. 

## Core Features (Phase 1 Execution)
* **The Ghost Entry:** Zero-friction onboarding. No email, no phone numbers, no centralized IDs. The app procedurally generates a temporary local alias (e.g., "Neon-Viper-9X").
* **End-to-End Encryption (E2EE):** Manual X3DH public key exchanges establish a secure AES-GCM encrypted tunnel. The relay only sees Base64 noise.
* **Synchronized Destruction:** Dual-timer logic. A Master Session Flush timer controls the identity's lifespan, while strict Time-to-Live (TTL) countdowns are embedded directly into individual message payloads.
* **Plausible Deniability (The Mask):** An OS-level visual shield. The app minimizes into a fully functional Calculator UI. The true E2EE interface only unlocks when a specific, numerical "Stealth Code" is entered.

## The Onion Architecture
Stealth Chat is built on a strict separation of concerns to ensure the UI, the cryptography, and the transport layers never cross-contaminate.

* **Layer 1 (Core):** Flutter-driven reactive UI and ephemeral local storage (SQLite/SharedPreferences).
* **Layer 2 (Security):** The Cryptographic Black Box handling key derivation and AES-GCM payload locking.
* **Layer 3 (Routing):** Smart middleware dictating state.
* **Layer 4 (Transport):** Currently running via a stateless Node.js WebSocket relay (IP: 10.0.2.2 for emulator testing).

## Future Roadmap (Post-Hackathon)
Our operating philosophy is growth through deliberate discomfort. To make this production-grade, the next evolution includes:
* **Automated Forward Secrecy:** Implementing the Double Ratchet algorithm.
* **True Serverless P2P Mesh:** WebRTC DataChannels and Google Nearby Connections (Bluetooth/Wi-Fi Direct) for offline, infrastructure-free communication.
* **Optical Handshakes:** Zero-trust QR code scanning for public key exchanges.
* **Anti-Forensics:** Encrypted-at-rest local databases that become mathematically unrecoverable upon an Identity Flush.

## Team NULLptr
*Built with cross-disciplinary friction by:*
* **Chandransh Gupta**
* **Ameen Thaj**
