import MEGASwiftUI
import SwiftUI

struct PhotoLibraryZoomControl: View {
    @Binding var zoomState: PhotoLibraryZoomState
    @Environment(\.editMode) var editMode
    
    var body: some View {
        zoomControl()
            .alignmentGuide(.trailing, computeValue: { d in d[.trailing] + 12})
            .alignmentGuide(.top, computeValue: { d in d[.top] - 5})
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
    
    // MARK: - Private
    private func zoomControl() -> some View {
        HStack {
            zoomOutButton()
            Divider()
                .padding(EdgeInsets(top: 13, leading: 3, bottom: 13, trailing: 3))
            zoomInButton()
        }
        .frame(width: 80, height: 40)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
    
    private func zoomInButton() -> some View {
        Button {
            zoomState.zoom(.in)
        } label: {
            Image(systemName: "plus")
                .imageScale(.large)
        }
        .foregroundColor(zoomState.canZoom(.in) ? MEGAAppColor.Photos.zoomButtonForeground.color : MEGAAppColor.Gray._8E8E93.color)
        .disabled(!zoomState.canZoom(.in))
    }
    
    private func zoomOutButton() -> some View {
        Button {
            zoomState.zoom(.out)
        } label: {
            Image(systemName: "minus")
                .imageScale(.large)
        }
        .foregroundColor(zoomState.canZoom(.out) ? MEGAAppColor.Photos.zoomButtonForeground.color : MEGAAppColor.Gray._8E8E93.color)
        .disabled(!zoomState.canZoom(.out))
    }
}
