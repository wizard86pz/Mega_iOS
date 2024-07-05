import MEGADomain
import MEGASdk
import MEGASwift

public struct TransfersListenerRepository: TransfersListenerRepositoryProtocol {
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        AsyncStream { continuation in
            let delegate = PrivateTransferDelegate {
                continuation.yield($0)
            }
            continuation.onTermination = { @Sendable _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .main)
        }.eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}

private class PrivateTransferDelegate: NSObject, MEGATransferDelegate {
    private let onTransferFinish: (TransferEntity) -> Void
    
    init(onTransferFinish: @escaping (TransferEntity) -> Void) {
        self.onTransferFinish = onTransferFinish
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        onTransferFinish(transfer.toTransferEntity())
    }
}

public extension TransfersListenerRepository {
    static var newRepo: TransfersListenerRepository {
        .init(sdk: MEGASdk.sharedSdk)
    }
}
