# Shipping & Payments Implementation

## Architecture Overview

### Secure Address Sharing via Julia Handshake

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Setup                                               │
│    └─ Add shipping address to carrier bag "addresses"       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Purchase Event (arethaUserPurchase spell)                │
│    ├─ Stripe payment processed                              │
│    ├─ Purchase BDO created (item, price, timestamp)         │
│    ├─ Address BDO created:                                  │
│    │  ├─ New keypair generated (Sessionless)                │
│    │  ├─ Address data encrypted                             │
│    │  ├─ addressBdoPubKey stored with purchase             │
│    │  └─ Posted to BDO service                              │
│    └─ Julia handshake initiated:                            │
│       ├─ Add addressBdoPubKey as coordinatingKey (buyer)    │
│       └─ Merchant adds as interactingKey                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Julia Handshake Completion                               │
│    └─ Cryptographic proof merchant is authorized            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Address Retrieval (getShippingAddress spell)             │
│    ├─ Merchant casts spell with addressBdoPubKey            │
│    ├─ Spell verifies Julia handshake completed              │
│    ├─ Returns decrypted shipping address                    │
│    └─ Merchant can now ship item                            │
└─────────────────────────────────────────────────────────────┘
```

## Data Structures

### Address in Carrier Bag

```json
{
  "addresses": [
    {
      "id": "uuid-v4",
      "name": "Home",
      "recipientName": "John Doe",
      "street": "123 Main St",
      "street2": "Apt 4B",
      "city": "San Francisco",
      "state": "CA",
      "zip": "94102",
      "country": "US",
      "phone": "+1-555-123-4567",
      "isPrimary": true,
      "createdAt": "2025-01-15T10:30:00Z"
    }
  ]
}
```

### Address BDO

```json
{
  "type": "shipping-address",
  "purchaseId": "purchase-bdo-pubkey",
  "address": {
    "recipientName": "John Doe",
    "street": "123 Main St",
    "street2": "Apt 4B",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "country": "US",
    "phone": "+1-555-123-4567"
  },
  "buyerUUID": "buyer-fount-uuid",
  "merchantUUID": "merchant-fount-uuid",
  "createdAt": "2025-01-15T10:35:00Z",
  "expiresAt": "2025-02-15T10:35:00Z"
}
```

### Purchase BDO

```json
{
  "type": "purchase",
  "itemId": "item-bdo-pubkey",
  "itemName": "Handmade Candle",
  "price": 2500,
  "currency": "usd",
  "buyerUUID": "buyer-fount-uuid",
  "sellerUUID": "seller-fount-uuid",
  "stripePaymentIntent": "pi_abc123",
  "addressBdoPubKey": "address-bdo-pubkey",
  "status": "paid",
  "createdAt": "2025-01-15T10:35:00Z"
}
```

## MAGIC Spells

### 1. arethaUserPurchase (Enhanced)

**Input:**
```json
{
  "itemId": "item-bdo-pubkey",
  "price": 2500,
  "currency": "usd",
  "paymentMethodId": "pm_abc123",
  "shippingAddressId": "address-uuid-from-carrier-bag"
}
```

**Process:**
1. Validate user has sufficient funds or payment method
2. Create Stripe PaymentIntent
3. Process payment (3D Secure if needed)
4. Create Purchase BDO
5. Create Address BDO with new keypair
6. Add address BDO coordinating key to buyer's Julia keys
7. Return purchase details + addressBdoPubKey to merchant

**Output:**
```json
{
  "success": true,
  "purchaseBdoPubKey": "purchase-pubkey",
  "addressBdoPubKey": "address-pubkey",
  "stripePaymentIntent": "pi_abc123",
  "handshakeRequired": true
}
```

### 2. getShippingAddress (New)

**Input:**
```json
{
  "addressBdoPubKey": "address-bdo-pubkey",
  "merchantUUID": "merchant-fount-uuid"
}
```

**Process:**
1. Verify caller is the authorized merchant
2. Check Julia handshake completed between:
   - Address BDO coordinating key (buyer)
   - Merchant interacting key
3. Fetch and decrypt address BDO
4. Return shipping address

**Output:**
```json
{
  "success": true,
  "address": {
    "recipientName": "John Doe",
    "street": "123 Main St",
    "street2": "Apt 4B",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "country": "US",
    "phone": "+1-555-123-4567"
  },
  "purchaseId": "purchase-bdo-pubkey"
}
```

### 3. initiateJuliaHandshake (Helper)

**Input:**
```json
{
  "addressBdoPubKey": "address-bdo-pubkey",
  "merchantUUID": "merchant-fount-uuid"
}
```

**Process:**
1. Merchant adds address BDO pubKey as interacting key
2. Buyer already has it as coordinating key (auto-added during purchase)
3. Julia performs cryptographic handshake
4. Returns handshake status

## Stripe Integration

### iOS Setup

**Podfile:**
```ruby
pod 'Stripe', '~> 23.0'
pod 'StripePaymentSheet', '~> 23.0'
```

**Code:**
```swift
import StripePaymentSheet

func processPayment(amount: Int, itemId: String, addressId: String) {
    // 1. Create payment intent via MAGIC spell
    castSpell("createPaymentIntent", components: [
        "amount": amount,
        "currency": "usd",
        "itemId": itemId
    ]) { result in
        guard let clientSecret = result["clientSecret"] as? String else { return }

        // 2. Present Stripe payment sheet
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "The Advancement"

        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )

        paymentSheet.present(from: self) { result in
            switch result {
            case .completed:
                // 3. Complete purchase with address
                self.completePurchase(itemId: itemId, addressId: addressId)
            case .canceled:
                print("Payment canceled")
            case .failed(let error):
                print("Payment failed: \(error)")
            }
        }
    }
}
```

### Android Setup

**build.gradle.kts:**
```kotlin
dependencies {
    implementation("com.stripe:stripe-android:20.37.0")
}
```

**Code:**
```kotlin
import com.stripe.android.PaymentConfiguration
import com.stripe.android.paymentsheet.PaymentSheet

fun processPayment(amount: Int, itemId: String, addressId: String) {
    // 1. Create payment intent via MAGIC spell
    viewModel.castSpell("createPaymentIntent", mapOf(
        "amount" to amount,
        "currency" to "usd",
        "itemId" to itemId
    )) { result ->
        val clientSecret = result["clientSecret"] as? String ?: return@castSpell

        // 2. Present Stripe payment sheet
        val paymentSheet = PaymentSheet(this, ::onPaymentSheetResult)
        paymentSheet.presentWithPaymentIntent(
            clientSecret,
            PaymentSheet.Configuration("The Advancement")
        )
    }
}

fun onPaymentSheetResult(result: PaymentSheetResult) {
    when (result) {
        is PaymentSheetResult.Completed -> {
            // Complete purchase with address
            completePurchase(itemId, addressId)
        }
        is PaymentSheetResult.Canceled -> {
            Log.d(TAG, "Payment canceled")
        }
        is PaymentSheetResult.Failed -> {
            Log.e(TAG, "Payment failed", result.error)
        }
    }
}
```

## Implementation Checklist

### Phase 1: Address Management
- [ ] Add "addresses" collection to carrier bag (iOS/Android)
- [ ] Create address management UI
- [ ] Add address to CarrierBagViewController
- [ ] Add address to Android CarrierBagActivity

### Phase 2: Address BDO Creation
- [ ] Implement address BDO schema
- [ ] Generate keypair for address BDO
- [ ] Post address BDO to BDO service
- [ ] Store addressBdoPubKey with purchase

### Phase 3: Julia Integration
- [ ] Add Julia endpoint for address handshake
- [ ] Auto-add coordinatingKey on purchase
- [ ] Merchant adds interactingKey
- [ ] Verify handshake completion

### Phase 4: MAGIC Spells
- [ ] Enhance arethaUserPurchase with address creation
- [ ] Implement getShippingAddress spell
- [ ] Implement initiateJuliaHandshake spell
- [ ] Add spell validation and error handling

### Phase 5: Stripe Integration
- [ ] Add Stripe SDK to iOS
- [ ] Add Stripe SDK to Android
- [ ] Implement payment sheet UI
- [ ] Handle 3D Secure
- [ ] Set up webhooks for payment confirmation

### Phase 6: Testing
- [ ] Test address save/retrieve
- [ ] Test purchase flow end-to-end
- [ ] Test Julia handshake
- [ ] Test address retrieval after handshake
- [ ] Test Stripe payment processing

## Security Considerations

1. **Address Encryption**: Address BDO is encrypted, only accessible via Julia handshake
2. **Time-Limited Access**: Address BDOs have expiration (30 days by default)
3. **Single-Use**: Each purchase gets unique address BDO + keys
4. **Revocation**: Buyer can revoke access by removing coordinating key
5. **Audit Trail**: All address access logged via BDO service

## Privacy Benefits

- **No Central Database**: Addresses never stored in plaintext on servers
- **Cryptographic Authorization**: Only parties who complete Julia handshake can access
- **Buyer Control**: Buyer explicitly authorizes each address share
- **Automatic Expiration**: Old shipping addresses automatically expire
- **Revocable**: Buyer can revoke access at any time
