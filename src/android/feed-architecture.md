# Feed Architecture Diagram

```mermaid
graph TD
    subgraph Collections
        C1[Collection 1<br/>Music Library]
        C2[Collection 2<br/>Podcast Archive]
    end

    subgraph Feeds
        F1[Feed 1<br/>Latest Tracks]
        F2[Feed 2<br/>Recent Episodes]
    end

    subgraph Receiver
        R[Feed Receiver<br/>Aggregator]
    end

    subgraph Players
        P1[Player 1<br/>Mobile App]
        P2[Player 2<br/>Web Browser]
        P3[Player 3<br/>Desktop Client]
        P4[Player 4<br/>Smart Speaker]
    end

    C1 -->|produces| F1
    C2 -->|produces| F2

    F1 -->|consumed by| R
    F2 -->|consumed by| R

    R -->|streams to| P1
    R -->|streams to| P2
    R -->|streams to| P3
    R -->|streams to| P4

    style C1 fill:#ec4899,stroke:#be185d,color:#fff
    style C2 fill:#ec4899,stroke:#be185d,color:#fff
    style F1 fill:#8b5cf6,stroke:#6d28d9,color:#fff
    style F2 fill:#8b5cf6,stroke:#6d28d9,color:#fff
    style R fill:#10b981,stroke:#059669,color:#fff
    style P1 fill:#3b82f6,stroke:#1d4ed8,color:#fff
    style P2 fill:#3b82f6,stroke:#1d4ed8,color:#fff
    style P3 fill:#3b82f6,stroke:#1d4ed8,color:#fff
    style P4 fill:#3b82f6,stroke:#1d4ed8,color:#fff
```

## Architecture Description

**Collections** (Pink):
- Collection 1: Music Library - Source of music tracks
- Collection 2: Podcast Archive - Source of podcast episodes

**Feeds** (Purple):
- Feed 1: Latest Tracks - RSS/streaming feed from music collection
- Feed 2: Recent Episodes - RSS/streaming feed from podcast collection

**Receiver** (Green):
- Single aggregation point that consumes both feeds
- Normalizes and merges content from multiple sources
- Manages playback queue and state

**Players** (Blue):
- Player 1: Mobile App - iOS/Android application
- Player 2: Web Browser - Browser-based player
- Player 3: Desktop Client - Native desktop application
- Player 4: Smart Speaker - Voice-controlled device

All players connect to the same receiver for synchronized content delivery.
