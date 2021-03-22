//
//  WalletInfo.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct CardWallet: Codable {
    public let index: Int
    public var status: WalletStatus
    public var curve: EllipticCurve?
    public var settingsMask: SettingsMask?
    public var publicKey: Data?
    public var signedHashes: Int?
    
    init(index: Int, status: WalletStatus, curve: EllipticCurve? = nil, settingsMask: SettingsMask? = nil, publicKey: Data? = nil, signedHashes: Int? = nil) {
        self.index = index
        self.status = status
        self.curve = curve
        self.settingsMask = settingsMask
        self.publicKey = publicKey
        self.signedHashes = signedHashes
    }
    
    init(from response: CreateWalletResponse, with curve: EllipticCurve, settings: SettingsMask?) {
        self.index = response.walletIndex
        self.status = WalletStatus(from: response.status)
        self.curve = curve
        self.settingsMask = settings
        self.publicKey = response.walletPublicKey
        self.signedHashes = 0
    }
    
    var emptyCopy: CardWallet {
        .init(index: index, status: .empty)
    }
}

public enum WalletStatus: Int, Codable {
    case empty = 1
    case loaded = 2
    case purged = 3


    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercasingFirst()
        switch stringValue {
        case "empty":
            self = .empty
        case "loaded":
            self = .loaded
        case "purged":
            self = .purged
        default:
            throw TangemSdkError.decodingFailed("Failed to decode WalletStatus")
        }
    }
    
    public init(from cardStatus: CardStatus) {
        switch cardStatus {
        case .empty, .notPersonalized:
            self = .empty
        case .loaded:
            self = .loaded
        case .purged:
            self = .purged
        }
    }
}
