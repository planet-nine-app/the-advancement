# ✨ The Enchantment Emporium - Design Document

## Overview

**The Enchantment Emporium** is a mystical location within The Advancement app where users can cast MAGIC protocol spells to create Planet Nine services. It serves as an abstraction layer for creating enchantments (services/features) via spell casting rather than traditional payment flows.

## Concept

The Enchantment Emporium is like a magical shop where instead of buying products, you **cast spells** to create services. Each enchantment is a MAGIC protocol spell that creates a public BDO representing a Planet Nine service.

### Key Principles

1. **Spell-Based Creation** - Services created via MAGIC spells, not traditional "purchase" flows
2. **Enchantment Abstraction** - Each service is an "enchantment" with mystical theming
3. **Public Accessibility** - Enchantments create public BDOs accessible via emojicodes
4. **Extensible** - Easy to add new enchantments over time
5. **Integrated with MAGIC** - Uses existing MAGIC protocol infrastructure

## User Journey

### 1. Discovering the Emporium

```
Main App Screen
    ↓
🏰 Tap "Enchantment Emporium" icon
    ↓
Emporium Home View
```

### 2. Browsing Enchantments

```
Emporium Home
    ↓
View available enchantments:
  - 🔮 Glyphenge (Link Tapestry)
  - 🌟 [Future enchantments]
    ↓
Tap enchantment to view details
```

### 3. Casting an Enchantment

```
Enchantment Detail View
    ↓
"Cast Enchantment" button
    ↓
MAGIC Spell Execution:
  1. Validate requirements (has links, has MP/nineum)
  2. Create BDO with user's data
  3. Make BDO public → generate emojicode
  4. Save emojicode to carrierBag
    ↓
Success View:
  - Display emojicode
  - "Copy" button
  - "Share" button
  - "View Tapestry" button
```

## UI Design

### Emporium Home View

```
┌─────────────────────────────────┐
│   ✨ The Enchantment Emporium    │
│                                 │
│   Weave magic into reality      │
│   through ancient spells        │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  🔮 Glyphenge               │ │
│ │  Link Tapestry Weaver       │ │
│ │                             │ │
│ │  Weave your links into a    │ │
│ │  mystical public tapestry   │ │
│ │                             │ │
│ │  Cost: 10 MP or 100 nineum  │ │
│ │                             │ │
│ │  [Cast Enchantment →]       │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  🌟 Coming Soon...          │ │
│ │  More enchantments await    │ │
│ └─────────────────────────────┘ │
│                                 │
│         [Close]                 │
└─────────────────────────────────┘
```

### Glyphenge Detail View

```
┌─────────────────────────────────┐
│   🔮 Glyphenge Enchantment      │
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │      [Mystical Symbol]      │ │
│ │         Preview             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│  Link Tapestry Weaver           │
│                                 │
│  Transform your carrierBag      │
│  links into a beautiful public  │
│  tapestry accessible to anyone  │
│  via an emojicode rune.         │
│                                 │
│  ✨ What You Get:               │
│  • Public link tapestry         │
│  • Shareable emojicode rune     │
│  • 3 mystical layouts           │
│  • No tracking or surveillance  │
│                                 │
│  📋 Requirements:               │
│  ✅ At least 1 link in bag      │
│  ✅ 10 MP or 100 nineum         │
│                                 │
│  📊 Your Links: 6 links ready   │
│  💰 Your Balance: 150 MP        │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Cast Glyphenge         │   │
│  │  (10 MP)                │   │
│  └─────────────────────────┘   │
│                                 │
│         [Back]                  │
└─────────────────────────────────┘
```

### Success View (Post-Casting)

```
┌─────────────────────────────────┐
│   ✨ Enchantment Cast! ✨       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      🔮                     │ │
│ │   Glyphenge Created         │ │
│ └─────────────────────────────┘ │
│                                 │
│  Your link tapestry has been    │
│  woven into the fabric of       │
│  Planet Nine!                   │
│                                 │
│  Your Emojicode Rune:           │
│                                 │
│  ┌─────────────────────────┐   │
│  │  😀🔗💎🌟💎🎨🐉📌      │   │
│  │     [Tap to Copy]        │   │
│  └─────────────────────────┘   │
│                                 │
│  Share this rune with anyone!   │
│  They can view your tapestry    │
│  at:                            │
│                                 │
│  glyphenge.com?emojicode=...    │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Share Emojicode         │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  View My Tapestry        │   │
│  └─────────────────────────┘   │
│                                 │
│         [Done]                  │
└─────────────────────────────────┘
```

## Technical Architecture

### View Controller Structure

```
EnchantmentEmporiumViewController
├── EmporiumHomeView (List of available enchantments)
├── EnchantmentDetailView (Details for specific enchantment)
└── EnchantmentSuccessView (Post-casting confirmation)
```

### Enchantment Data Model

```swift
struct Enchantment {
    let id: String              // "glyphenge"
    let name: String            // "Glyphenge"
    let subtitle: String        // "Link Tapestry Weaver"
    let description: String     // Full description
    let icon: String            // "🔮"
    let costMP: Int?            // 10
    let costNineum: Int?        // 100
    let requirements: [String]  // ["At least 1 link"]
    let spell: String           // MAGIC spell name
    let previewImage: String?   // Optional preview
}
```

### MAGIC Spell Flow

```swift
// Glyphenge Enchantment Spell
func castGlyphenge() async throws -> String {
    // 1. Validate requirements
    guard let carrierBag = SharedUserDefaults.getCarrierBag(),
          let links = carrierBag["links"] as? [[String: Any]],
          !links.isEmpty else {
        throw EnchantmentError.noLinks
    }

    // 2. Check MP/nineum balance via MAGIC
    let balance = await checkMAGICBalance()
    guard balance.mp >= 10 || balance.nineum >= 100 else {
        throw EnchantmentError.insufficientFunds
    }

    // 3. Create Glyphenge BDO with temporary keys
    let glyphengeBDO: [String: Any] = [
        "title": "My Glyphenge",
        "type": "glyphenge",
        "links": links,
        "createdAt": ISO8601DateFormatter().string(from: Date())
    ]

    let tempKeys = sessionless.generateKeys()

    // 4. Create BDO user
    let bdoResponse = try await createBDO(
        pubKey: tempKeys.publicKey,
        data: glyphengeBDO
    )

    // 5. Make BDO public → get emojicode
    let emojicode = try await makeBDOPublic(
        uuid: bdoResponse.uuid,
        keys: tempKeys
    )

    // 6. Deduct MP/nineum via MAGIC spell
    try await castSpell(
        spell: "glyphengePayment",
        params: ["cost": 10]
    )

    // 7. Save emojicode to carrierBag "store"
    let glyphengeRecord: [String: Any] = [
        "type": "glyphenge",
        "emojicode": emojicode,
        "url": "https://glyphenge.com?emojicode=\(emojicode)",
        "createdAt": ISO8601DateFormatter().string(from: Date())
    ]

    SharedUserDefaults.addToCarrierBagCollection("store", item: glyphengeRecord)

    // 8. Return emojicode
    return emojicode
}
```

## Navigation Integration

### Main App Menu

Add new button/icon to main navigation:

```swift
// MainViewController
let emporiumButton = UIButton()
emporiumButton.setTitle("✨ Enchantment Emporium", for: .normal)
emporiumButton.addTarget(self, action: #selector(openEmporium), for: .touchUpInside)

@objc func openEmporium() {
    let emporiumVC = EnchantmentEmporiumViewController()
    let navController = UINavigationController(rootViewController: emporiumVC)
    navController.modalPresentationStyle = .fullScreen
    present(navController, animated: true)
}
```

## Future Enchantments

The Enchantment Emporium is designed to be extensible. Future enchantments could include:

### 🌟 Portal Weave
Create a teleportation portal for cross-base commerce

### 🎭 Persona Forge
Generate a public identity card/profile

### 📜 Covenant Seal
Create and publish magical contracts

### 🎵 Harmonic Resonance
Publish a music playlist or audio feed

### 🏺 Artifact Vault
Create a public NFT gallery

## Implementation Checklist

- [ ] Create `EnchantmentEmporiumViewController.swift`
- [ ] Create `Enchantment.swift` data model
- [ ] Create HTML views for Emporium UI (or SwiftUI)
- [ ] Implement `castGlyphenge()` spell method
- [ ] Integrate with MAGIC protocol for payment
- [ ] Add BDO creation and public-making logic
- [ ] Implement emojicode display and sharing
- [ ] Add navigation button to main app
- [ ] Create success/error animations
- [ ] Write tests for enchantment casting flow

## Color Scheme & Theming

**Primary Colors:**
- Deep Purple: `#1a0033` (background)
- Mystic Purple: `#a78bfa` (accents)
- Enchantment Green: `#10b981` (success/cast button)
- Gold: `#fbbf24` (highlights/icons)

**Fonts:**
- Headers: System Bold
- Body: System Regular
- Mystical elements: Monospace for emojicodes

**Visual Effects:**
- Shimmer/glow effects on enchantment cards
- Particle effects when casting spells
- Pulse animation on "Cast" button
- Fade-in animations for success view

## Testing Strategy

1. **Unit Tests**
   - Validate requirements checking
   - Test BDO creation logic
   - Verify emojicode generation

2. **Integration Tests**
   - Full spell casting flow
   - MAGIC protocol payment
   - CarrierBag storage

3. **UI Tests**
   - Navigation flows
   - Button interactions
   - Success/error states

## Success Metrics

- Time to cast first enchantment
- Success rate of spell casting
- User satisfaction with mystical theming
- Number of enchantments cast per user
- Sharing rate of emojicodes
