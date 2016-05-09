# CoolWallet iOS app

CoolWallet iOS app connects with the CoolWallet (a wireless Bitcoin cold storage hardware device) and makes commands via Bluetooth Low Energy. This app uses [blockr.io](http://blockr.io/documentation/api) and [blockchain.info](https://blockchain.info/api) APIs to get account balances, transaction histories and broadcast transactions to the Bitcoin network.

# Features

- BIP 32 HD wallet
- Used addresses coloured grey, unused addresses coloured white
- Set security policies for CoolWallet
- Sync balance with the blockchain to set card display
- HD wallet recovery
- Send recipient's address and amount from app to CoolWallet for signing
- Receive signed transaction from CoolWallet to broadcast to the Bitcoin network
- Transaction history lists
- Enter OTP shown on CoolWallet display and send it back for verification
- Generate address QR code and request amount
- Notifications for receiving bitcoins and device connection

# Installation

1. Download the project

2. Install [CoacoPods](https://cocoapods.org/) if you haven’t got it:
```sh
$ sudo gem install cocoapods
```

3. Build CoolWallet from the root directory:
```sh
pod install
```
4. Open the CoolWallet.xcworkspace file in Xcode.

***Note:*** 
As Bluetooth is required to communicate with the CoolWallet, testing can only be done on a real device (iOS 8.1 or later).

#Bluetooth API

Please see [this document](https://github.com/CoolBitX-Technology/coolwallet-ios/blob/master/docs/CW-SPEC-0002-se_spi_apdu_spec_v0110.pdf) with specifications for commands and responses.

