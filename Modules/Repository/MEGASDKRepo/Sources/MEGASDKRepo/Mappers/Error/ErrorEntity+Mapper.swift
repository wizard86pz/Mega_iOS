import MEGADomain
import MEGASdk

extension MEGAErrorType {
    public func toErrorTypeEntity() -> ErrorTypeEntity {
        switch self {
        case .apiOk:
            return .ok
        case .apiEInternal:
            return .internalError
        case .apiEArgs:
            return .badArguments
        case .apiEAgain:
            return .tryAgain
        case .apiERateLimit:
            return .tooManyRequest
        case .apiEFailed:
            return .failedPermanently
        case .apiETooMany:
            return .tooManyRequestForResource
        case .apiERange:
            return .outOfRange
        case .apiEExpired:
            return .resourceExpired
        case .apiENoent:
            return .resourceNotExists
        case .apiECircular:
            return .circularLink
        case .apiEAccess:
            return .accessDenied
        case .apiEExist:
            return .resourceAlreadyExist
        case .apiEIncomplete:
            return .incompleteRequest
        case .apiEKey:
            return .cryptographic
        case .apiESid:
            return .badSessionID
        case .apiEBlocked:
            return .resourceAdministrativelyBlocked
        case .apiEOverQuota:
            return .quotaExceeded
        case .apiETempUnavail:
            return .resourceTemporarilyUnavailable
        case .apiETooManyConnections:
            return .tooManyConnections
        case .apiEWrite:
            return .canNotWrite
        case .apiERead:
            return .canNotRead
        case .apiEAppKey:
            return .invalidApplicationKey
        case .apiESSL:
            return .invalidSSLKey
        case .apiEgoingOverquota:
            return .notEnoughQuota
        case .apiERolledBack:
            return .rolledBack
        case .apiEMFARequired:
            return .multiFactorAuthenticationRequired
        case .apiEMasterOnly:
            return .businessMasterAccountAccessOnly
        case .apiEBusinessPastDue:
            return .businessAccountExpired
        case .apiEPaywall:
            return .overDiskQuotaPaywall
        @unknown default:
            return .ok
        }
    }
}

extension MEGAError {
    public func toErrorEntity() -> ErrorEntity {
        ErrorEntity(
            type: self.type.toErrorTypeEntity(),
            name: self.name,
            value: self.value
        )
    }
}
