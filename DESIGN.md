# Project KOSMOS — Design Document

**Version:** *0.0 (pre-alpha)*

**Status:** *Active development*

**License:** *AGPL*

**Lead designer:** *seren1ty*

**Codename:** **Project KOSMOS**

**Release name:** [not yet chosen]


## Technical Specification

### Client
- **Engine:** Godot 4.x
- **Language:** GDScript (90%), C# (optional)
- **Renderer:** Compatibility (OpenGL 3.3)
- **Platforms:** Windows 7+ (32/64), Linux
- **Size:** <500 MB (alpha), planned <1 GB (release)

### Server
- **Language:** Go 1.21+
- **Database:** MariaDB
- **Protocol:** WebSocket (JSON + packet length)
- **Authentication:** XOR (pre-alpha, implemented now), OpenSSL (alpha release)

### Scalability
- Single system → constellation → region (foundation laid)
- On Alpha launch: several regions, a total of about 100 systems
- Projected: hundreds (maybe thousands) of systems


## Concept

Project KOSMOS is an open-source, massively multiplayer space game in the spirit of EVE Online, but with a focus on accessibility, low system requirements, and a friendly community. Players explore a static universe of systems, constellations, and regions, fight, trade, mine resources, and build corporations.

Key differences from EVE:
- Starting in a neutral corporation (similar to AIR)
- Anthro races instead of humans (with a light and sweet presentation)
- Simplified yet deep economy
- Emphasis on small groups (alliances will come later)


## Lore and Universe

### Timeline
The distant future. Four superpowers (2 vs. 2) are waging a cold war.
[No names yet, so for now you can call them Not Caldari, Not Amarr, or something like that. But I'll say right away, they don't resemble their "references" in character.]

### Races
The player can choose one of several furry races. Races are NOT tied to the starting faction.
So far, only four races have been developed:
* Foxes - Not Caldari
* Deer - Not Amarr
* Tanuki - Not Minmatar
* Cats - Not Gallente

### Starter Corporation
The player starts in the neutral "KOSMOS Academy" (similar to AIR from EVE).
This is a training corporation that provides the player's first ship, basic skills, and is not tied to any superpower.

### Narrative Tone
Space is harsh, but not hopeless. The lore has room for both serious moments and sweet details (:


## Gameplay

### Main Activities (at alpha release)

#### Flying and Combat
- Controls: Click to move, hotkeys, EVE-like kinematics
- Four weapon types:
- Lasers (hitscan, instant)
- Hybrid (hitscan with low latency)
- Ballistic (hitscan with high latency)
- Missiles (entity with a lifespan)
- Ships: 5 ships per faction (20 ships total). Classes: frigates, cruisers, battleships, and haulers

#### Economy and Crafting
- Asteroid Mining → Raw Materials
- Module and Ship Production from Blueprints
- Market (trading between players, taxes at stations)

#### Social Interaction
- Corporations (guilds/clans) — no alliances at launch
- Chats (local, corporate, private)
- Friends / Blacklist

#### PvE Content
- Combat Anomalies (simple, 1-3 waves of enemies)
- Agent Missions (trivial: delivery, kill N enemies, mine N ore)
- Mining Anomalies (dense asteroid fields)

### What will NOT be implemented in the near future
- Alliances (later, after corporations stabilize)
- VR Mode (never)
- Landing Missions (NEVER EVER)


## Roadmap

### Pre-alpha (current, June 2026)
- [x] Basic server architecture
- [x] Authorization and character creation
- [x] Inventory
- [x] One 3D scene (station)
- [x] Universe template
- [ ] Space flights (EVE controls)

### Alpha
- [ ] Market
- [ ] Corporations
- [ ] 20 ships (5 ships each for the main factions)
- [ ] Simple enemy AI
- [ ] Simple agent missions
- [ ] Mining
- [ ] Simple producing system


## Interface

### Main Screens

#### Station (Dock)
- Left side - similar to EVE Online NEOCOM
- Right side - station UI(services, station inventory and hangar, station guests, agents)
- Center - 3D view of dock and ship
#### Space
- Left side - NEOCOM
- Right side - overview, current object selection and actions
- Left-down - chat window
- Center-down - ship UI (Shield, Armor, Capacitor, current modules)

### Style
- EVE Online Rhea style (early ProtonUI) as a reference for interface design
- ATLYSS style (and Kiseff in general) as a reference for character and possibly ship design
- Pixel textures


## Project Support

### Needed
- **Godot Developers** (GDScript)
- **Go Developers** (server)
- **3D Artists** (low-poly ship and station models)
- **2D Artists** (UI, portraits, icons)
- **Testers** (bug reports, balance)
- **Writers** (lore, item descriptions, missions)

### What is not accepted
- Changes that violate the project vision (the lead designer will resolve controversial issues)
- Changes that increase system requirements without good reason
- Content that violates licenses
