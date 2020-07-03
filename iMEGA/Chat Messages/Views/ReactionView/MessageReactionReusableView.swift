import AlignedCollectionViewFlowLayout
import MessageKit

protocol MessageReactionReusableViewDelegate: class {
    func emojiTapped(_ emoji: String, chatMessage: ChatMessage, sender: UIView)
    func emojiLongPressed(_ emoji: String, chatMessage: ChatMessage, sender: UIView)
}

class MessageReactionReusableView: MessageReusableView {
    var emojis = [String]()
    var indexPath: IndexPath?
    //    var reactionContainerView = ReactionContainerView()
    private lazy var reactionContainerView: ReactionContainerView = {
        let reactionContainerView = ReactionContainerView()
        reactionContainerView.delegate = self
        addSubview(reactionContainerView)

        return reactionContainerView
    }()
    
    var chatMessage: ChatMessage? {
        didSet {
            reactionContainerView.chatMessage = chatMessage
            reactionContainerView.delegate = self
        }
    }

    weak var delegate: MessageReactionReusableViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        reactionContainerView.pin.vertically().horizontally(pin.safeArea)
    }

    func isFromCurrentSender(message: MessageType) -> Bool {
        return UInt64(message.sender.senderId) == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle
    }
    
}

extension MessageReactionReusableView: ReactionEmojiViewDelegate {
    func emojiTapped(_ emoji: String, sender: UIView) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }
        
        delegate.emojiTapped(emoji, chatMessage: chatMessage, sender: sender)
    }
    
    func emojiLongPressed(_ emoji: String, sender: UIView) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }
        
        delegate.emojiLongPressed(emoji, chatMessage: chatMessage, sender: sender)
    }
}
