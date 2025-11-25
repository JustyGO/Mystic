# MysticScrolls - Ancient Knowledge Exchange

## Overview
MysticScrolls is a decentralized library for trading ancient scrolls of knowledge as NFTs on the Stacks blockchain. Scribes can inscribe mystical scrolls, offer them in the bazaar, and receive tributes on all future exchanges of their wisdom.

## Features
- **Scroll Inscription**: Inscribe unique mystical scrolls with ancient knowledge
- **Bazaar Trading**: Offer scrolls for exchange with custom pricing
- **Tribute System**: Automatic tribute payments to original scribes (up to 10%)
- **Secure Exchanges**: Built-in keeper verification and secure STX transfers
- **Grand Keeper Authority**: Administrative functions for library management

## Smart Contract Functions

### Administrative Functions

#### `appoint-keeper`
Appoint a new Grand Keeper of the library.
```clarity
(appoint-keeper (successor principal))
```
- **Access**: Grand Keeper only
- **Parameters**: 
  - `successor`: Principal address of the new keeper
- **Returns**: `(ok true)` on success

#### `retrieve-keeper`
Query the current Grand Keeper address.
```clarity
(retrieve-keeper)
```
- **Access**: Public read-only
- **Returns**: Current Grand Keeper principal

### Scroll Management

#### `inscribe`
Inscribe a new mystical scroll NFT.
```clarity
(inscribe (inscription (string-ascii 256)) (tribute uint))
```
- **Parameters**:
  - `inscription`: Ancient knowledge content (1-256 characters)
  - `tribute`: Tribute percentage in basis points (max 1000 = 10%)
- **Returns**: `(ok scroll-num)` with the new scroll number
- **Restrictions**: Inscription must not be empty, tribute cannot exceed 10%

#### `examine`
View scroll details.
```clarity
(examine (scroll-num uint))
```
- **Parameters**: `scroll-num` - Number of the scroll to examine
- **Returns**: Scroll data including keeper, scribe, inscription, and tribute

### Bazaar Functions

#### `offer-scroll`
Place a scroll for exchange in the bazaar.
```clarity
(offer-scroll (scroll-num uint) (cost uint))
```
- **Access**: Current scroll keeper only
- **Parameters**:
  - `scroll-num`: Number of the scroll to offer
  - `cost`: Price in microSTX (µSTX)
- **Returns**: `(ok true)` on success

#### `withdraw-offering`
Remove a scroll from the bazaar.
```clarity
(withdraw-offering (scroll-num uint))
```
- **Access**: Current vendor only
- **Parameters**: `scroll-num` - Number of the scroll to withdraw
- **Returns**: `(ok true)` on success

#### `obtain`
Obtain a scroll from the bazaar.
```clarity
(obtain (scroll-num uint))
```
- **Parameters**: `scroll-num` - Number of the scroll to obtain
- **Process**:
  1. Transfers tribute payment to original scribe
  2. Transfers remaining amount to current vendor
  3. Transfers NFT ownership to obtainer
  4. Removes bazaar offering
- **Returns**: `(ok true)` on success

#### `examine-offering`
View bazaar offering details.
```clarity
(examine-offering (scroll-num uint))
```
- **Parameters**: `scroll-num` - Number of the offered scroll
- **Returns**: Offering data including cost and vendor

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-forbidden` | Caller is not authorized |
| u101 | `err-wrong-keeper` | Caller is not the scroll keeper |
| u102 | `err-no-offering` | Bazaar offering does not exist |
| u103 | `err-price-insufficient` | Offering cost must be greater than 0 |
| u104 | `err-scroll-absent` | Scroll does not exist |
| u105 | `err-corrupt-data` | Inscription data is corrupted |
| u106 | `err-tribute-excessive` | Tribute rate exceeds 10% limit |
| u107 | `err-null-entity` | Invalid null entity provided |

## Usage Examples

### Inscribing a New Scroll
```clarity
(contract-call? .mystic-scrolls inscribe "The Secrets of Dimensional Travel" u750)
;; Creates scroll with 7.5% tribute rate
```

### Offering a Scroll
```clarity
(contract-call? .mystic-scrolls offer-scroll u1 u2000000)
;; Offers scroll #1 for 2 STX
```

### Obtaining a Scroll
```clarity
(contract-call? .mystic-scrolls obtain u1)
;; Obtains scroll #1 at offered cost
```

## Security Considerations
- Only the current keeper can offer their scrolls
- Only the Grand Keeper can appoint a successor
- Null entity validation prevents invalid principal assignments
- Tribute rates are capped at 10% (1000 basis points)
- All STX transfers are atomic and secured by the blockchain

## Deployment
Deploy this contract to the Stacks blockchain using Clarinet or the Stacks CLI.

```bash
clarinet deploy --network mainnet
```
