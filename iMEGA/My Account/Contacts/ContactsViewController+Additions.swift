import Contacts
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAPresentation
import SwiftUI

extension ContactsViewController {
    private static let throttler = Throttler(timeInterval: 0.5, dispatchQueue: .main)
    
    func selectUsers(_ users: [MEGAUser]) {
        guard users.count > 0 else { return }
        selectedUsersArray.addObjects(from: users)
        addItems(toList: users.map { ItemListModel(user: $0) })
        tableView.reloadData()
    }
    
    private var pageTitle: String {
        switch contactsMode {
        case .default:
            return Strings.Localizable.contactsTitle
        case .shareFoldersWith:
            return Strings.Localizable.shareWith
        case .folderSharedWith:
            return Strings.Localizable.sharedWith
        case .chatStartConversation:
            return Strings.Localizable.startConversation
        case .scheduleMeeting, .chatAddParticipant:
            return Strings.Localizable.addParticipants
        case .chatAttachParticipant:
            return Strings.Localizable.sendContact
        case .chatCreateGroup:
            return Strings.Localizable.addParticipants
        case .chatNamingGroup:
            return Strings.Localizable.newGroupChat
        case .inviteParticipants:
            return Strings.Localizable.Meetings.Panel.inviteParticipants
        @unknown default:
            return ""
        }
    }
    
    @objc
    func setNavigationBarTitles() {
        let title = pageTitle
        self.navigationItem.title = title
    }
    
    @objc
    func setNavigationItemStackedPlacement() {
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
    }

    @objc
    func setupContactsNotVerifiedHeader() {
        let hostingView = UIHostingController(rootView: WarningView(viewModel: .init(warningType: .contactsNotVerified)))

        guard let hostingViewUIView = hostingView.view else { return }

        hostingViewUIView.backgroundColor = MEGAAppColor.Yellow._FED429.uiColor

        contactsNotVerifiedView.isHidden = true
        contactsNotVerifiedView.addSubview(hostingViewUIView)
        hostingViewUIView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingViewUIView.topAnchor.constraint(equalTo: contactsNotVerifiedView.topAnchor),
            hostingViewUIView.leadingAnchor.constraint(equalTo: contactsNotVerifiedView.leadingAnchor),
            hostingViewUIView.trailingAnchor.constraint(equalTo: contactsNotVerifiedView.trailingAnchor),
            hostingViewUIView.bottomAnchor.constraint(equalTo: contactsNotVerifiedView.bottomAnchor)
        ])
    }

    @objc
    func handleContactsNotVerifiedHeaderVisibility() {
        contactsNotVerifiedView.isHidden = !viewModel.shouldShowUnverifiedContactsBanner(
            contactsMode: contactsMode,
            selectedUsersArray: selectedUsersArray,
            visibleUsersArray: visibleUsersArray
        )
    }

    @objc
    func createViewModel() {
        self.viewModel = ContactsViewModel(
            sdk: MEGASdk.shared
        )
    }

    @objc
    func extractEmails(_ contacts: [CNContact]) -> [NSString] {
        let emails = contacts.extractEmails()
        return emails.map { NSString(string: $0) }
    }
}

// MARK: - MEGARequestDelegate

extension ContactsViewController: MEGARequestDelegate {
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else { return }
        switch request.type {
        case .MEGARequestTypeGetAttrUser:
            let userAttribute = UserAttributeEntity(rawValue: request.paramType)
            guard userAttribute == .firstName || userAttribute == .lastName else { return }
            Self.throttler.start { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.reloadUI()
                }
            }
        default:
            return
        }
    }
}
