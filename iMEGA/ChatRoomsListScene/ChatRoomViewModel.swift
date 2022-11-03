import MEGADomain
import Combine
import MEGASwift
import Foundation
import MEGAUI
import Combine

final class ChatRoomViewModel: ObservableObject, Identifiable {
    let chatListItem: ChatListItemEntity
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let router: ChatRoomsListRouting
    private var chatNotificationControl: ChatNotificationControl
    private let notificationCenter: NotificationCenter

    private(set) var primaryAvatar: UIImage?
    private(set) var secondaryAvatar: UIImage?
    private(set) var description: String?
    private(set) var hybridDescription: ChatRoomHybridDescriptionViewState?
    @Published var chatStatusColor: UIColor?
    @Published var showDNDTurnOnOptions = false
    @Published var existsInProgressCallInChatRoom = false
    
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool

    private(set) var displayDateString: String?

    private var subscriptions = Set<AnyCancellable>()
    private var loadingChatRoomInfoTask: Task<Void, Never>?
    private let isRightToLeftLanguage: Bool
    
    var isViewOnScreen = false
    
    init(chatListItem: ChatListItemEntity,
         router: ChatRoomsListRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatNotificationControl: ChatNotificationControl,
         isRightToLeftLanguage: Bool,
         notificationCenter: NotificationCenter = .default) {
        self.chatListItem = chatListItem
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.userUseCase = userUseCase
        self.chatNotificationControl = chatNotificationControl
        self.isRightToLeftLanguage = isRightToLeftLanguage
        self.notificationCenter = notificationCenter
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        
        if chatListItem.group == false {
            let chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatListItem.peerHandle)
            self.chatStatusColor = chatStatusColor(forChatStatus: chatStatus)
            listeningForChatStatusUpdate()
        }
        
        self.contextMenuOptions = constructContextMenuOptions()
        self.displayDateString = formattedLastMessageSentDate()
        self.loadingChatRoomInfoTask = createLoadingChatRoomInfoTask(isRightToLeftLanguage: isRightToLeftLanguage)
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: chatListItem.chatId)
        monitorActiveCallChanges()
    }
    
    //MARK: - Interface methods
    
    func cancelLoading() {
        loadingChatRoomInfoTask?.cancel()
        loadingChatRoomInfoTask = nil
    }
    
    func showDetails() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return }
        router.showDetails(forChatId: chatListItem.chatId, unreadMessagesCount: chatRoom.unreadCount)
    }
    
    func presentMoreOptionsForChat(){
        router.presentMoreOptionsForChat(
            withDNDEnabled: chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        ) { [weak self] in
            self?.toggleDND()
        } markAsReadAction: { [weak self] in
            guard let self else { return }
            self.chatRoomUseCase.setMessageSeenForChat(forChatId: self.chatListItem.chatId, messageId: self.chatListItem.lastMessageId)
        } infoAction: { [weak self] in
            self?.showChatRoomInfo()
        } archiveAction: { [weak self] in
            guard let self else { return }
            self.chatRoomUseCase.archive(true, chatId: self.chatListItem.chatId)
        }
    }
    
    func dndTurnOnOptions() -> [DNDTurnOnOption] {
        ChatNotificationControl.dndTurnOnOptions()
    }
    
    func turnOnDNDOption(_ option: DNDTurnOnOption) {
        chatNotificationControl.turnOnDND(chatId: chatListItem.chatId, option: option)
    }
    
    func archiveChat() {
        chatRoomUseCase.archive(true, chatId: chatListItem.chatId)
    }
    
    func pushNotificationSettingsChanged() {
        let newValue = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        guard isMuted != newValue else { return }
        
        contextMenuOptions = constructContextMenuOptions()
        isMuted = newValue
        objectWillChange.send()
    }
    
    //MARK: - Private methods
    private func formattedLastMessageSentDate() -> String? {
        guard let seventhDayPriorDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to:Date()) else { return nil }
        
        if Calendar.autoupdatingCurrent.isDateInToday(chatListItem.lastMessageDate) {
            return chatListItem.lastMessageDate.string(withDateFormat: "HH:mm")
        } else if chatListItem.lastMessageDate.compare(seventhDayPriorDate) == .orderedDescending {
            return chatListItem.lastMessageDate.string(withDateFormat: "EEE")
        } else {
            return chatListItem.lastMessageDate.string(withDateFormat: "dd/MM/yy")
        }
    }
    
    private func constructContextMenuOptions() -> [ChatRoomContextMenuOption] {
        var options: [ChatRoomContextMenuOption] = []
        
        if chatListItem.unreadCount > 0 {
            options.append(
                ChatRoomContextMenuOption(
                    title: Strings.Localizable.markAsRead,
                    imageName: Asset.Images.Chat.ContextualMenu.markUnreadMenu.name,
                    action: { [weak self] in
                        guard let self else { return }
                        self.chatRoomUseCase.setMessageSeenForChat(
                            forChatId: self.chatListItem.chatId,
                            messageId: self.chatListItem.lastMessageId
                        )
                    })
            )
        }
        
        let isDNDEnabled = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        
        options += [
            ChatRoomContextMenuOption(
                title: isDNDEnabled ? Strings.Localizable.unmute : Strings.Localizable.mute,
                imageName: Asset.Images.Chat.mutedChat.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.toggleDND()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.info,
                imageName: Asset.Images.Generic.info.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.showChatRoomInfo()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.archiveChat,
                imageName: Asset.Images.Chat.ContextualMenu.archiveChatMenu.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.archiveChat()
                })
        ]
        
        return options
    }
        
    private func createLoadingChatRoomInfoTask(isRightToLeftLanguage: Bool) -> Task<Void, Never> {
        Task { [weak self] in
            let chatId = chatListItem.chatId
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    do {
                        try await self?.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
                    } catch {
                        MEGALogDebug("Unable to fetch avatar for \(chatId) - \(error.localizedDescription)")
                    }
                }
                
                group.addTask { [weak self] in
                    do {
                        try await self?.updateDescription()
                    } catch {
                        MEGALogDebug("Unable to load description for \(chatId) - \(error.localizedDescription)")
                    }
                }
            }
            
            guard let self, self.isViewOnScreen else { return }
            
            do {
                try Task.checkCancellation()
                await self.sendObjectChangeNotification()
            } catch {
                MEGALogDebug("Task cancelled for \(chatId)")
            }
        }
    }
    
    @MainActor
    private func sendObjectChangeNotification() {
        objectWillChange.send()
    }
    
    private func showChatRoomInfo() {
        if chatListItem.group {
            guard let chatIdString = chatRoomUseCase.base64Handle(forChatId: chatListItem.chatId),
                  MEGALinkManager.joiningOrLeavingChatBase64Handles.notContains(where: { element in
                      if let elementId = element as? String, elementId == chatIdString {
                          return true
                      }
                      return false
                  }) else {
                      return
                  }
            
            router.showGroupChatInfo(forChatId: chatListItem.chatId)
        } else {
            guard let userHandle = chatRoomUseCase.peerHandles(forChatId: chatListItem.chatId).first,
                    let userEmail = chatRoomUseCase.contactEmail(forUserHandle: userHandle) else {
                return
            }
            
            router.showContactDetailsInfo(forUseHandle: userHandle, userEmail: userEmail)
        }
    }
    
    private func toggleDND() {
        if chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId) {
            chatNotificationControl.turnOffDND(chatId: chatListItem.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func fetchAvatar(isRightToLeftLanguage: Bool) async throws {
        if chatListItem.group {
            if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) {
                if chatRoom.peerCount == 0 {
                    if let chatTitle = chatListItem.title,
                       let avatar = createAvatar(usingName: chatTitle, isRightToLeftLanguage: isRightToLeftLanguage) {
                        updatePrimaryAvatar(avatar)
                    }
                } else {
                    if let handle = chatRoom.peers.first?.handle,
                        let avatar = try await createAvatar(withHandle: handle, isRightToLeftLanguage: isRightToLeftLanguage) {
                        updatePrimaryAvatar(avatar)
                    }
                    
                    try Task.checkCancellation()

                    if chatRoom.peers.count > 1,
                        let avatar = try await createAvatar(withHandle: chatRoom.peers[1].handle, isRightToLeftLanguage: isRightToLeftLanguage) {
                        updateSecondaryAvatar(avatar)
                    }
                }
            }
        } else {
            if let avatar = try await createAvatar(withHandle: chatListItem.peerHandle, isRightToLeftLanguage: isRightToLeftLanguage) {
                updatePrimaryAvatar(avatar)
            }
            
            try Task.checkCancellation()

            let downloadedAvatar = try await downloadAvatar()
            updatePrimaryAvatar(downloadedAvatar)
        }
    }
    
    private func updateDescription() async throws {
        switch chatListItem.lastMessageType {
        case .loading:
            updateDescription(withMessage: Strings.Localizable.loading)
        case .invalid:
            updateDescription(withMessage: Strings.Localizable.noConversationHistory)
        case .attachment:
            try await updateDescriptionForAttachment()
        case .voiceClip:
            try await updateDescriptionForVoiceClip()
        case .contact:
            try await updateDescriptionForContact()
        case .truncate:
            try await updateDescriptionForTruncate()
        case .privilegeChange:
            try await updateDescriptionForPrivilageChange()
        case .alterParticipants:
            try await updateDescriptionForAlertParticipants()
        case .setRetentionTime:
           try await updateDescriptionForRententionTime()
        case .chatTitle:
            try await updateDesctiptionWithChatTitleChange()
        case .callEnded:
            await updateDescriptionForCallEnded()
        case .callStarted:
            updateDescription(withMessage: Strings.Localizable.callStarted)
        case .publicHandleCreate:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.createdAPublicLinkForTheChat)
        case .publicHandleDelete:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.removedAPublicLinkForTheChat)
        case .setPrivateMode:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.enabledEncryptedKeyRotation)
        default:
            try await updateDescriptionForDefault()
        }
    }
    
    private func chatStatusColor(forChatStatus chatStatus: ChatStatusEntity) -> UIColor? {
        switch chatStatus {
        case .online:
            return Colors.Chat.Status.online.color
        case .offline:
            return Colors.Chat.Status.offline.color
        case .away:
            return Colors.Chat.Status.away.color
        case .busy:
            return Colors.Chat.Status.busy.color
        default:
            return nil
        }
    }
    
    private func listeningForChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange(forUserHandle: chatListItem.peerHandle)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] status in
                guard let self = self else { return }
                self.chatStatusColor = self.chatStatusColor(forChatStatus: status)
            })
            .store(in: &subscriptions)
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase.monitorChatCallStatusUpdate()
            .sink { [weak self] call in
                guard let self, call.chatId == self.chatListItem.chatId else { return }
                self.existsInProgressCallInChatRoom = call.status == .inProgress || call.status == .userNoPresent
            }
            .store(in: &subscriptions)
    }
    
    private func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool) async throws -> UIImage?   {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle),
              let chatTitle = chatListItem.title  else {
            return nil
        }
        
        return try await userImageUseCase.createAvatar(withUserHandle: chatListItem.peerHandle,
                                                       base64Handle: base64Handle,
                                                       avatarBackgroundHexColor: avatarBackgroundHexColor,
                                                       backgroundGradientHexColor: nil,
                                                       name: chatTitle,
                                                       isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private func createAvatar(usingName name: String, isRightToLeftLanguage: Bool, size: CGSize = CGSizeMake(100, 100)) -> UIImage?  {
        let initials = name
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap({ $0.count > 1 ? String($0.prefix(1)).uppercased() : nil })
            .joined(separator: "")
                
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: Colors.Chat.Avatar.background.color,
            backgroundGradientColor: UIColor.mnz_grayDBDBDB(),
            textColor: .white,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private func downloadAvatar() async throws -> UIImage {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: chatListItem.peerHandle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.downloadAvatar(withUserHandle: chatListItem.peerHandle, base64Handle: base64Handle)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == userUseCase.myHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUseCase.userDisplayNames(forPeerIds: [userHandle], chatId: chatListItem.chatId)
            return usernames.first
        }
    }
    
    private func updateDescriptionForAttachment() async throws {
        let senderString = chatListItem.group ? try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true) : nil
        guard let lastMessage = chatListItem.lastMessage else { return }
        let components = lastMessage.components(separatedBy: "\\x01")
        let message: String
        if components.count == 1 {
            message = Strings.Localizable.attachedFile(lastMessage)
        } else {
            message = Strings.Localizable.attachedXFiles(String(format: "%tu", components.count))
        }
        if let senderString {
            updateDescription(withMessage: "\(senderString): \(message)")
        } else {
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForCallEnded() async {
        let components = chatListItem.lastMessage?.components(separatedBy: String(format: "%c", 0x01))
        let durationString = components?.first ?? ""
        let duration = chatListItem.group ? nil : Int(durationString)
        
        let endCallReason: ChatMessageEndCallReasonEntity
        if let components,
            components.count >= 2,
            let secondComponentIntValue = Int(components[1]) {
            endCallReason = ChatMessageEndCallReasonEntity(secondComponentIntValue) ?? .ended
        } else {
            endCallReason = .ended
        }

        let message = message(forEndCallReason: endCallReason,
                              userHandle: chatListItem.lastMessageSender,
                              duration: duration)
        
        updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForRententionTime() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        
        if chatRoom.retentionTime <= 0 {
            let message = removeFormatters(fromString: Strings.Localizable.A1SABDisabledMessageClearing.b(sender))
            updateDescription(withMessage: message)
        } else {
            guard let retention = retentionDuration(fromSeconds: Int(chatRoom.retentionTime)) else {
                return
            }
            let message = removeFormatters(fromString: Strings.Localizable.A1SABChangedTheMessageClearingTimeToBA2SAB.b(sender, retention))
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForAlertParticipants() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false)
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
              let lastMessageUsername = try await chatRoomUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], chatId: chatRoom.chatId).first else {
            return
        }
        
        switch chatListItem.lastMessagePriv {
        case .unknown:
            if let sender, sender != lastMessageUsername {
                var message = Strings.Localizable.wasRemovedFromTheGroupChatBy
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                message = message.replacingOccurrences(of: "[B]", with: sender)
                updateDescription(withMessage: message)
            } else {
                var message = Strings.Localizable.leftTheGroupChat
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                updateDescription(withMessage: message)
            }
        case .joinedGroupChat:
            if let sender, sender != lastMessageUsername {
                var message = Strings.Localizable.joinedTheGroupChatByInvitationFrom
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                message = message.replacingOccurrences(of: "[B]", with: sender)
                updateDescription(withMessage: message)
            } else {
                let message = Strings.Localizable.joinedTheGroupChat(lastMessageUsername)
                updateDescription(withMessage: message)
            }
        default:
            break
        }
    }
    
    private func updateDescriptionForPrivilageChange() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
              let lastMessageUsername = try await chatRoomUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], chatId: chatRoom.chatId).first else {
            return
        }
        
        var message: String?
        
        switch chatListItem.lastMessagePriv {
        case .invalid:
            message = Strings.Localizable.Chat.Message.ChangedRole.readOnly
        case .alterParticipants:
            message = Strings.Localizable.Chat.Message.ChangedRole.standard
        case .truncate:
            message = Strings.Localizable.Chat.Message.ChangedRole.host
        default:
            break
        }
        
        guard var message else {
            MEGALogDebug("Privilage code did not match")
            return
        }
        
        message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
        message = message.replacingOccurrences(of: "[B]", with: sender)
        message = removeFormatters(fromString: message)
        updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForTruncate() async throws  {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        let message = Strings.Localizable.clearedTheChatHistory.replacingOccurrences(of: "[A]", with: sender)
        updateDescription(withMessage: message)
    }
    
    private func message(forEndCallReason endCallReason: ChatMessageEndCallReasonEntity,
                         userHandle: HandleEntity,
                         duration: Int?) -> String {
        switch endCallReason {
        case .ended, .byModerator:
            if chatListItem.group {
                if let duration, duration > 0 {
                    let durationString = callDurationString(fromSeconds: duration) ?? "\(duration)"
                    var message = Strings.Localizable.AGroupCallEndedAC.durationC
                    message = message.replacingOccurrences(of: "[/C]", with: durationString)
                    message = removeFormatters(fromString: message)
                    return message
                }
                
                return Strings.Localizable.groupCallEnded
            } else {
                if let duration {
                    return "\(Strings.Localizable.callEnded) \(Strings.Localizable.duration(callDurationString(fromSeconds: duration) ?? "\(duration)"))"
                } else {
                    return "\(Strings.Localizable.callEnded)"
                }
            }
        case .rejected:
            return Strings.Localizable.callWasRejected
        case .noAnswer:
            if userHandle == userUseCase.myHandle {
                return Strings.Localizable.callWasNotAnswered
            } else {
                return Strings.Localizable.missedCall
            }
        case .failed:
            return Strings.Localizable.callFailed
        case .cancelled:
            if userHandle == userUseCase.myHandle {
                return Strings.Localizable.callWasCancelled
            } else {
                return Strings.Localizable.missedCall
            }
        }
    }
    
    private func removeFormatters(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(/\[.{1, 2}\]/, with: "")
        } else {
            formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression)
        }
        
        return formattedString
    }
    
    private func updateDescriptionWithSender(usingMessage message: (Any) -> String) async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else { return }
        updateDescription(withMessage: message(sender))
    }
    
    private func updateDesctiptionWithChatTitleChange() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        var changedGroupChatNameTo = Strings.Localizable.changedGroupChatNameTo
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[A]", with: sender)
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[B]", with: chatListItem.lastMessage ?? "")
        updateDescription(withMessage: changedGroupChatNameTo)
    }
    
    private func updateDescriptionForContact() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false)
        guard let lastMessage = chatListItem.lastMessage else {
            return
        }
        
        let components = lastMessage.components(separatedBy: "\\x01")
        let message: String
        if components.count == 1 {
            message = Strings.Localizable.sentContact(lastMessage)
        } else {
            message = Strings.Localizable.sentXContacts(String(format: "%tu", components.count))
        }
        
        if let sender, chatListItem.group {
            updateDescription(withMessage: "\(sender): \(message)")
        } else {
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForVoiceClip() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true)
        let message = chatRoomUseCase.message(forChatId: chatListItem.chatId, messageId: chatListItem.lastMessageId)
        
        guard let duration = TimeInterval(message?.nodes?.first?.duration ?? 0).timeDisplayString(),
              let image = UIImage(named: chatListItem.unreadCount > 0 ? "voiceMessage" : "voiceMessageGrey") else {
            return
        }

        if let sender {
            updateHybridDescription(with: "\(sender):", image: image, duration: duration)
        } else {
            updateHybridDescription(with: nil, image: image, duration: duration)
        }
    }
    
    private func updateDescriptionForDefault() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true)
        if chatListItem.lastMessageType == .containsMeta {
            let message = chatRoomUseCase.message(forChatId: chatListItem.chatId, messageId: chatListItem.lastMessageId)
            
            if message?.containsMeta?.type == .geolocation,
                let image = UIImage(named: chatListItem.unreadCount > 0 ? "locationMessage" : "locationMessageGrey") {
                if let sender {
                    updateHybridDescription(with: "\(sender):", image: image, duration: Strings.Localizable.pinnedLocation)
                } else {
                    updateHybridDescription(with: nil, image: image, duration: Strings.Localizable.pinnedLocation)
                }
            }
        }
        
        if let message = chatListItem.lastMessage {
            if let sender {
                updateDescription(withMessage: sender + ": " + message)

            } else {
                updateDescription(withMessage: message)
            }
        }
    }
    
    private func callDurationString(fromSeconds seconds: Int) -> String? {
        if seconds >= 60 {
            if seconds >= 3600 {
                return seconds.string(allowedUnits: [.hour, .minute])
            } else {
                return seconds.string(allowedUnits: [.minute])
            }
        } else {
            return seconds.string(allowedUnits: [.second])
        }
    }
    
    private func retentionDuration(fromSeconds seconds: Int) -> String? {
        let secondsInAnHour = 60 * 60
        let secondsInADay = secondsInAnHour * 24
        let secondsInAWeek = secondsInADay * 7
        let secondsInAMonth = secondsInADay * 30
        let secondsInAYear = secondsInADay * 365
        
        let hoursModulo = seconds % secondsInAnHour
        let daysModulo = seconds % secondsInADay
        let weeksModulo = seconds % secondsInAWeek
        let monthsModulo = seconds % secondsInAMonth
        let yearModulo = seconds % secondsInAYear
        
        if yearModulo == 0 {
            return Strings.Localizable.General.Format.RetentionPeriod.year(1)
        } else if (monthsModulo == 0) {
            let months = seconds / secondsInAMonth
            return Strings.Localizable.General.Format.RetentionPeriod.month(months)
        } else if (weeksModulo == 0) {
            let weeks = seconds / secondsInAWeek
            return Strings.Localizable.General.Format.RetentionPeriod.week(weeks)
        } else if (daysModulo == 0) {
            let days = seconds / secondsInADay
            return Strings.Localizable.General.Format.RetentionPeriod.day(days)
        } else if (hoursModulo == 0) {
            let hours = seconds / secondsInAHour
            return Strings.Localizable.General.Format.RetentionPeriod.hour(hours)
        }
        
        return nil
    }
    
    private func updateHybridDescription(with sender: String?, image: UIImage, duration: String) {
        hybridDescription = ChatRoomHybridDescriptionViewState(sender: sender, image: image, duration: duration)
    }
    
    private func updateDescription(withMessage message: String) {
        description = message
    }
    
    private func updatePrimaryAvatar(_ avatar: UIImage) {
        primaryAvatar = avatar
    }
    
    private func updateSecondaryAvatar(_ avatar: UIImage) {
        secondaryAvatar = avatar
    }
}

extension ChatRoomViewModel: Equatable {
    static func == (lhs: ChatRoomViewModel, rhs: ChatRoomViewModel) -> Bool {
        lhs.chatListItem == rhs.chatListItem
    }
}
