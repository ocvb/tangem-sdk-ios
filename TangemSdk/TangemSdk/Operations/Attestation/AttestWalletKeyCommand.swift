//
//  AttestWalletKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `AttestWalletKeyCommand`.
public struct AttestWalletKeyResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Random salt generated by the card.
    public let salt: Data
    /// `Challenge` and `salt` signed with the wallet private key.
    public let walletSignature: Data
    /// Challenge, used to check wallet
    public let challenge: Data
    /// Confirmation signature of the wallet ownership.  COS: 2.01+.
    /// - `ConfirmationMode.none` :  No signature will be returned.
    /// - `ConfirmationMode.static` :  Wallet's public key signed with the card's private key.
    /// - `ConfirmationMode.dynamic`: Wallet's public key, `challenge`, and `publicKeySalt`, signed with the card's private key.
    public let cardSignature: Data?
    /// Optional random salt, generated by the card for  `dynamic` `confirmationMode`.  COS: 2.01+.
    public let publicKeySalt: Data?
    /// Counter of `AttestWalletKey` command executions. A very big value of this counter may indicate a hacking attempts.  COS: 2.01+.
    let counter: Int?
}

/// This command proves that the wallet private key from the card corresponds to the wallet public key.  Standard challenge/response scheme is used
@available(iOS 13.0, *)
public final class AttestWalletKeyCommand: Command {
    private var challenge: Data!
    private let walletPublicKey: Data
    private let confirmationMode: ConfirmationMode
    
    /// Default initializer
    /// - Parameters:
    ///   - publicKey: Public key of the wallet to check
    ///   - challenge: Optional challenge. If nil, it will be created automatically and returned in command response
    ///   - confirmationMode: Additional confirmation of the wallet ownership.  The card will return the `cardSignature` (a wallet's public key signed by the card's private key)  in response.  COS: 2.01+.
    public init(publicKey: Data, challenge: Data? = nil, confirmationMode: ConfirmationMode = .dynamic) {
        self.walletPublicKey = publicKey
        self.challenge = challenge
        self.confirmationMode = confirmationMode
    }
    
    deinit {
        Log.debug("AttestWalletKeyCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<AttestWalletKeyResponse>) {
        if challenge == nil {
            do {
                challenge = try CryptoUtils.generateRandomBytes(count: 16)
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
        
        transceive(in: session) {result in
            switch result {
            case .success(let checkWalletResponse):
                guard let curve = session.environment.card?.wallets[self.walletPublicKey]?.curve else {
                    completion(.failure(.cardError))
                    return
                }
                
                do {
                    let verifyResult = try self.verify(response: checkWalletResponse, curve: curve)
                    if verifyResult {
                        completion(.success(checkWalletResponse))
                    } else {
                        completion(.failure(.cardVerificationFailed))
                    }
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }
        
        guard let walletIndex = card.wallets[walletPublicKey]?.index else {
            throw TangemSdkError.walletNotFound
        }
        
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: card.cardId)
            .append(.challenge, value: challenge)
            .append(.walletIndex, value: walletIndex)
        
        //Otherwise, static confirmation will fail with the "invalidParams" error.
        if card.firmwareVersion >= .attestWalletConfirmation {
            switch confirmationMode {
            case .none:
                break
            case .static:
                try tlvBuilder.append(.publicKeyChallenge, value: Data())
            case .dynamic:
                try tlvBuilder.append(.publicKeyChallenge, value: challenge)
            }
        }
        
        return CommandApdu(.attestWalletKey, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AttestWalletKeyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return AttestWalletKeyResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            walletSignature: try decoder.decode(.walletSignature),
            challenge: self.challenge,
            cardSignature: try decoder.decode(.cardSignature),
            publicKeySalt: try decoder.decode(.publicKeySalt),
            counter: try decoder.decode(.checkWalletCounter))
    }
    
    private func verify(response: AttestWalletKeyResponse, curve: EllipticCurve) throws -> Bool {
        return try CryptoUtils.verify(curve: curve,
                                      publicKey: walletPublicKey,
                                      message: challenge + response.salt,
                                      signature: response.walletSignature)
    }
}

@available(iOS 13.0, *)
public extension AttestWalletKeyCommand {
    enum ConfirmationMode {
        case none
        case `static`
        case dynamic
    }
}
