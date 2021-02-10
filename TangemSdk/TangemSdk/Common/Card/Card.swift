//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: JSONStringConvertible {
	/// Unique Tangem card ID number.
	public let cardId: String?
	/// Name of Tangem card manufacturer.
	public let manufacturerName: String?
	/// Current status of the card.
	public var status: CardStatus?
	/// Version of Tangem COS.
	public let firmwareVersion: FirmwareVersion?
	/// Public key that is used to authenticate the card against manufacturer’s database.
	/// It is generated one time during card manufacturing.
	public let cardPublicKey: Data?
	/// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
	public let settingsMask: SettingsMask?
	/// Public key that is used by the card issuer to sign IssuerData field.
	public let issuerPublicKey: Data?
	/// Explicit text name of the elliptic curve used for all wallet key operations.
	/// Supported curves: ‘secp256k1’ and ‘ed25519’.
	public let curve: EllipticCurve?
	/// Total number of signatures allowed for the wallet when the card was personalized.
	public let maxSignatures: Int?
	/// Defines what data should be submitted to SIGN command.
	public let signingMethods: SigningMethod?
	/// Delay in centiseconds before COS executes commands protected by PIN2. This is a security delay value
	public let pauseBeforePin2: Int?
	/// Public key of the blockchain wallet.
	public var walletPublicKey: Data?
	/// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
	public let walletRemainingSignatures: Int?
	/// Total number of signed single hashes returned by the card in
	/// `SignCommand` responses since card personalization.
	/// Sums up array elements within all `SignCommand`.
	public var walletSignedHashes: Int?
	/// Any non-zero value indicates that the card experiences some hardware problems.
	/// User should withdraw the value to other blockchain wallet as soon as possible.
	/// Non-zero Health tag will also appear in responses of all other commands.
	public let health: Int?
	/// Whether the card requires issuer’s confirmation of activation
	public let isActivated: Bool
	/// A random challenge generated by personalisation that should be signed and returned
	/// to COS by the issuer to confirm the card has been activated.
	/// This field will not be returned if the card is activated
	public let activationSeed: Data?
	/// Returned only if `SigningMethod.SignPos` enabling POS transactions is supported by card
	public let paymentFlowVersion: Data?
	/// This value can be initialized by terminal and will be increased by COS on execution of every `SignCommand`.
	/// For example, this field can store blockchain “nonce" for quick one-touch transaction on POS terminals.
	/// Returned only if `SigningMethod.SignPos`  enabling POS transactions is supported by card.
	public let userCounter: Int?
	/// When this value is true, it means that the application is linked to the card,
	/// and COS will not enforce security delay if `SignCommand` will be called
	/// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
	/// to be signed made with `TlvTag.TerminalPublicKey`.
	public let terminalIsLinked: Bool
	/// Detailed information about card contents. Format is defined by the card issuer.
	/// Cards complaint with Tangem Wallet application should have TLV format.
	public let cardData: CardData?
	
	/// Set by ScanTask
	public var isPin1Default: Bool? = nil
	/// Set by ScanTask
	public var isPin2Default: Bool? = nil
	
	/// Available only for cards with COS v.4.0 and higher.
	public var pin2IsDefault: Bool? = nil
	
	/// Index of corresponding wallet
	public var walletIndex: Int? = nil
	/// Maximum number of wallets that can be created for this card
	public var walletsCount: Int? = nil
	
	public init(cardId: String?, manufacturerName: String?, status: CardStatus?, firmwareVersion: String?, cardPublicKey: Data?, settingsMask: SettingsMask?, issuerPublicKey: Data?, curve: EllipticCurve?, maxSignatures: Int?, signingMethods: SigningMethod?, pauseBeforePin2: Int?, walletPublicKey: Data?, walletRemainingSignatures: Int?, walletSignedHashes: Int?, health: Int?, isActivated: Bool, activationSeed: Data?, paymentFlowVersion: Data?, userCounter: Int?, terminalIsLinked: Bool, cardData: CardData?, remainingSignatures: Int? = nil, signedHashes: Int? = nil, challenge: Data? = nil, salt: Data? = nil, walletSignature: Data? = nil, walletIndex: Int? = nil, walletsCount: Int? = nil) {
		self.cardId = cardId
		self.manufacturerName = manufacturerName
		self.status = status
		self.cardPublicKey = cardPublicKey
		self.settingsMask = settingsMask
		self.issuerPublicKey = issuerPublicKey
		self.curve = curve
		self.maxSignatures = maxSignatures
		self.signingMethods = signingMethods
		self.pauseBeforePin2 = pauseBeforePin2
		self.walletPublicKey = walletPublicKey
		self.walletRemainingSignatures = walletRemainingSignatures
		self.walletSignedHashes = walletSignedHashes
		self.health = health
		self.isActivated = isActivated
		self.activationSeed = activationSeed
		self.paymentFlowVersion = paymentFlowVersion
		self.userCounter = userCounter
		self.terminalIsLinked = terminalIsLinked
		self.cardData = cardData
		self.walletIndex = walletIndex
		self.walletsCount = walletsCount
		
		if let version = firmwareVersion {
			self.firmwareVersion = FirmwareVersion(version: version)
		} else {
			self.firmwareVersion = nil
		}
	}
	
	public mutating func update(with response: CreateWalletResponse) {
		guard cardId == response.cardId, response.status == .loaded else {
			return
		}
	
		status = response.status
		walletPublicKey = response.walletPublicKey
	}
	
	public func updating(with response: CreateWalletResponse) -> Card {
		var card = self
		card.update(with: response)
		return card
	}
	
	public mutating func update(with response: PurgeWalletResponse) {
		guard cardId == response.cardId, response.status == .empty else {
			return
		}
		
		status = response.status
		walletPublicKey = nil
	}
	
	public func updating(with response: PurgeWalletResponse) -> Card {
		var card = self
		card.update(with: response)
		return card
	}
	
}

public extension Card {
	
	var firmwareVersionValue: Double? {
		firmwareVersion?.versionDouble
	}
	
	var isLinkedTerminalSupported: Bool {
		return settingsMask?.contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) ?? false
	}
	
	var cardType: FirmwareType {
		return firmwareVersion?.type ?? .special
	}
}
