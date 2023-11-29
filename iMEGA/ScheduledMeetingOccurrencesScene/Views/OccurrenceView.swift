import SwiftUI

struct OccurrenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let occurrence: ScheduleMeetingOccurrence
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?

    private enum Constants {
        static let headerHeight: CGFloat = 28
        static let rowHeight: CGFloat = 65
        static let avatarSize = CGSize(width: 28, height: 28)
        static let spacing: CGFloat = 0
        static let headerSpacing: CGFloat = 4
        static let headerBackgroundOpacity: CGFloat = 0.95
        static let headerTitleOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                Spacer()
                Text(occurrence.date)
                    .padding(.horizontal)
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? Color(UIColor.grayEBEBF5).opacity(Constants.headerTitleOpacity) : Color(UIColor.gray3C3C43).opacity(Constants.headerTitleOpacity))
                Divider()
                    .background(colorScheme == .dark ? Color(UIColor.gray545458) : Color(UIColor.gray3C3C43))
            }
            .background(colorScheme == .dark ? Color(UIColor.gray1D1D1D).opacity(Constants.headerBackgroundOpacity) : Color(UIColor.whiteF7F7F7).opacity(Constants.headerBackgroundOpacity))
            .frame(height: Constants.headerHeight)

            HStack(alignment: .center) {
                if let chatRoomAvatarViewModel {
                    ChatRoomAvatarView(viewModel: chatRoomAvatarViewModel, size: Constants.avatarSize)
                }
                VStack(alignment: .leading) {
                    Text(occurrence.title)
                        .font(.subheadline)
                    Text(occurrence.time)
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.grayD1D1D1) : Color(UIColor.gray515151))
                }
            }
            .frame(height: Constants.rowHeight)
        }
        .listRowInsets(EdgeInsets())
    }
}
