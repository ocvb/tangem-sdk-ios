//
//  SessionEnvironment.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

//All encryption modes
public enum EncryptionMode: Byte {
    case none = 0x00
    case fast = 0x01
    case strong = 0x02
}

public struct KeyPair: Equatable {
    public let privateKey: Data
    public let publicKey: Data
}


/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `SessionEnvironment`.
public struct SessionEnvironment {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    /// Current card, read by preflight `Read` command
    public var card: Card? = nil
    
    /// Hashed pin1 with sha256
    public var pin1: Data {
        return SessionEnvironment.pin1
    }
    
    /// Hashed pin2 with sha256
    public var pin2: Data = defaultPin2.sha256()
    
    /// Keys for Linked Terminal feature
    public var terminalKeys: KeyPair? = nil
    
    public var encryptionMode: EncryptionMode = .none
    public var encryptionKey: Data? = nil

    public var cvc: Data? = nil
    
    var legacyMode: Bool = true
    
    public var allowedCardTypes: [CardType] = [.sdk, .release, .unknown]

    public var handleErrors: Bool = true
    
    private static var pin1: Data = defaultPin1.sha256()
    
    public var isDefaultPin1: Bool {
        return SessionEnvironment.pin1 == SessionEnvironment.defaultPin1.sha256()
    }
    
    public var isDefaultPin2: Bool {
        return pin2 == SessionEnvironment.defaultPin2.sha256()
    }
    
    public init() {}
    
    /// Helper method for setting pin1 in string format. Calculates sha256 hash for you
    /// - Parameter pin1: pin1
    public mutating func set(pin1: String) {
        SessionEnvironment.pin1 = pin1.sha256()
    }
    
    /// Helper method for setting pin2 in string format.  Calculates sha256 hash for you
    /// - Parameter pin2: pin2
    public mutating func set(pin2: String) {
        self.pin2 = pin2.sha256()
    }
}
