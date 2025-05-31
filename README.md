# 🎲 StakeDraw

**A Decentralized Lottery Pool System Built on Stacks Blockchain**

StakeDraw is a transparent, fair, and secure lottery system that leverages the power of blockchain technology to create trustless lottery pools. Participants can buy entry tickets, and multiple champions are randomly selected to share the prize pool.

## ✨ Features

- **🔒 Trustless Operation**: Smart contract handles all operations automatically
- **🎯 Multiple Winners**: Support for multiple champions per draw
- **💰 Transparent Fees**: Configurable commission rates (max 20%)
- **⏰ Flexible Timing**: Customizable draw duration and refund windows
- **🛡️ Emergency Controls**: Pool master can pause draws if needed
- **📊 Real-time Tracking**: Monitor prize pools, entries, and draw status

## 🚀 Quick Start

### Prerequisites

- Stacks wallet with STX tokens
- Access to Stacks blockchain testnet/mainnet
- Basic understanding of smart contracts

### Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/stakedraw
   cd stakedraw
   ```

2. **Deploy the contract**
   ```bash
   clarinet deploy --network testnet
   ```

3. **Initialize your first draw**
   ```clarity
   (contract-call? .stakedraw initialize-new-draw u1000 u500 u1000000 u3 u5)
   ```

## 📖 How It Works

### 1. **Draw Creation**
The pool master creates a new lottery draw with:
- Duration in blocks
- Refund window period
- Entry ticket price
- Number of champions to select
- Commission rate

### 2. **Ticket Purchase**
Participants buy entry tickets by sending STX to the contract. Each ticket gives them a chance to win.

### 3. **Prize Pool Growth**
As more participants join, the prize pool grows. The pool master earns a small commission.

### 4. **Champion Selection**
After the draw period ends, champions are randomly selected using a verifiable random seed.

### 5. **Reward Distribution**
Champions can claim their share of the prize pool at any time after selection.

## 🎮 Usage Examples

### For Pool Masters

**Start a New Draw:**
```clarity
;; 7-day draw, 2-day refund window, 1 STX tickets, 5 winners, 3% fee
(contract-call? .stakedraw initialize-new-draw 
    u1008 u288 u1000000 u5 u3)
```

**Finalize and Draw Champions:**
```clarity
(contract-call? .stakedraw finalize-draw)
(contract-call? .stakedraw draw-champions u12345)
```

**Emergency Pause:**
```clarity
(contract-call? .stakedraw emergency-pause-draw)
```

### For Participants

**Buy Entry Tickets:**
```clarity
(contract-call? .stakedraw buy-entry-ticket)
```

**Request Refund (if within refund window):**
```clarity
(contract-call? .stakedraw request-entry-refund u2)
```

**Claim Champion Reward:**
```clarity
(contract-call? .stakedraw claim-champion-reward u0)
```

## 🔍 Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `initialize-new-draw` | Create a new lottery draw |
| `buy-entry-ticket` | Purchase a lottery ticket |
| `request-entry-refund` | Refund tickets within refund window |
| `finalize-draw` | End the draw and calculate rewards |
| `draw-champions` | Randomly select winners |
| `claim-champion-reward` | Winners claim their rewards |
| `emergency-pause-draw` | Emergency stop function |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-entry-fee` | Get current ticket price |
| `get-prize-pool-total` | Get total prize pool |
| `get-participant-entry-count` | Get user's ticket count |
| `is-draw-active` | Check if draw is active |
| `get-champion-details` | Get winner information |

## 🛡️ Security Features

- **Access Control**: Only pool master can manage draws
- **Balance Validation**: Ensures sufficient funds before transactions
- **Time-based Controls**: Enforces draw duration and refund windows
- **Overflow Protection**: Safe arithmetic operations
- **Emergency Stops**: Pool master can pause draws

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Test specific scenarios:
```bash
clarinet test tests/draw-lifecycle.test.ts
clarinet test tests/security.test.ts
```

## 📊 Contract Architecture

```
StakeDraw Contract
├── State Management
│   ├── Draw Status Variables
│   ├── Prize Pool Tracking
│   └── Participant Registry
├── Core Functions
│   ├── Draw Lifecycle Management
│   ├── Ticket Sales & Refunds
│   └── Champion Selection
└── Security Layer
    ├── Access Controls
    ├── Input Validation
    └── Emergency Functions
```


1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request


