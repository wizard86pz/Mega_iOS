import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct AlbumContentPickerView: View {
    @StateObject var viewModel: AlbumContentPickerViewModel
    var invokeDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            backgroundColor
            VStack(spacing: 0) {
                navigationBar
                
                PhotoLibraryContentView(
                    viewModel: viewModel.photoLibraryContentViewModel,
                    router: PhotoLibraryContentViewRouter(),
                    onFilterUpdate: nil
                )
                
                Spacer()
                footer
            }
        }
        .alert(isPresented: $viewModel.showSelectionLimitReachedAlert) {
            Alert(title: Text(Strings.Localizable.CameraUploads.Albums.AddItems.Alert.LimitReached.title),
                  message: Text(Strings.Localizable.CameraUploads.Albums.AddItems.Alert.LimitReached.message(viewModel.selectLimit)),
                  dismissButton: .default(Text(Strings.Localizable.ok)))
        }
        .onChange(of: viewModel.shouldDismiss) {
            if $0 {
                dismiss()
            }
        }
        .edgesIgnoringSafeArea(.vertical)
    }
    
    var navigationBar: some View {
        VStack(spacing: 0) {
            Text(viewModel.navigationTitle)
                .lineLimit(1)
                .font(.footnote)
                .foregroundColor(.primary)
                .padding(.bottom, 14)
                .padding(.top, 18)
                .padding(.horizontal, 30)
            
            HStack {
                Button {
                    viewModel.onCancel()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundColor(textColor)
                }.padding(10)
                
                Text(viewModel.photoSourceLocationNavigationTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                Button {
                    viewModel.onDone()
                } label: {
                    Text(Strings.Localizable.done)
                        .font(.body.bold())
                        .foregroundColor(textColor.opacity(viewModel.isDoneButtonDisabled ? 0.5 : 1))
                }.padding(10)
                .disabled(viewModel.isDoneButtonDisabled)
            }.padding(.bottom, 10)
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if !viewModel.shouldRemoveFilter {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.onFilter()
                    } label: {
                        Text(Strings.Localizable.filter)
                            .font(.body)
                            .foregroundColor(textColor)
                    }.padding(20)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._F7F7F7.color
    }
    
    private var textColor: Color {
        colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
