//
//  CheckWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CheckWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Random salt generated by the card
    public let salt: Data
    /// Challenge and salt signed with the wallet private key.
    public let walletSignature: Data
    /// Challenge, used to check wallet
    public let challenge: Data
}

/// This command proves that the wallet private key from the card corresponds to the wallet public key.  Standard challenge/response scheme is used
public final class CheckWalletCommand: Command {
    public typealias Response = CheckWalletResponse

    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: walletPublicKey) }

    private var challenge: Data?
    private let walletPublicKey: Data

    /// Default initializer
    /// - Parameters:
    ///   - publicKey: Public key of the wallet to check
    ///   - challenge: Optional challenge. If nil, it will be created automatically and returned in command response
    public init(publicKey: Data, challenge: Data? = nil) {
        self.walletPublicKey = publicKey
        self.challenge = challenge
    }
    
    deinit {
        Log.debug("CheckWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.status == .notPersonalized {
            return .notPersonalized
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        return nil
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<CheckWalletResponse>) {
        if challenge == nil {
            do {
                challenge = try CryptoUtils.generateRandomBytes(count: 16)
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
        
        transieve(in: session) {result in
            switch result {
            case .success(let checkWalletResponse):
                guard let curve = session.environment.card?.wallets[self.walletPublicKey]?.curve else {
                    completion(.failure(.cardError))
                    return
                }
                
                guard let verifyResult = self.verify(response: checkWalletResponse, curve: curve) else {
                    completion(.failure(.cryptoUtilsError))
                    return
                }
                
                if verifyResult {
                    completion(.success(checkWalletResponse))
                } else {
                    completion(.failure(.cardVerificationFailed))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challenge)
            .append(.walletPublicKey, value: walletPublicKey)
		
        return CommandApdu(.checkWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CheckWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return CheckWalletResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            walletSignature: try decoder.decode(.walletSignature),
            challenge: self.challenge!)
    }
    
    private func verify(response: CheckWalletResponse, curve: EllipticCurve) -> Bool? {
        return CryptoUtils.verify(curve: curve,
                                  publicKey: walletPublicKey,
                                  message: challenge! + response.salt,
                                  signature: response.walletSignature)
    }
}
