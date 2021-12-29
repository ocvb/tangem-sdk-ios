//
//  DeriveWalletPublicKeyTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 05.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class DeriveWalletPublicKeyTask: CardSessionRunnable {
    private let walletIndex: WalletIndex
    private let derivationPath: DerivationPath
    
    /// Derive wallet  public key according to BIP32 (Private parent key → public child key).
    /// Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - walletIndex: Index of the wallet
    ///   - derivationPath: Derivation path
    public init(walletIndex: WalletIndex, derivationPath: DerivationPath) {
        self.walletIndex = walletIndex
        self.derivationPath = derivationPath
    }
    
    deinit {
        Log.debug("DeriveWalletPublicKeyTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ExtendedPublicKey>) {
        guard let wallet = session.environment.card?.wallets[walletIndex] else {
            completion(.failure(TangemSdkError.walletNotFound))
            return
        }
        
        guard wallet.curve == .secp256k1 || wallet.curve == .ed25519 else {
            completion(.failure(TangemSdkError.unsupportedCurve))
            return
        }
        
        let readWallet = ReadWalletCommand(walletIndex: walletIndex, derivationPath: derivationPath)
        readWallet.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let chainCode = response.wallet.chainCode else {
                    completion(.failure(.cardError))
                    return
                }
                
                let childKey = ExtendedPublicKey(publicKey: response.wallet.publicKey, chainCode: chainCode)
                
                session.environment.card?.wallets[self.walletIndex]?.derivedKeys.appendIfNotContains(childKey)
                
                completion(.success(childKey))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
