import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class AlbumListViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testLoadAlbums_onAlbumsLoaded_systemAlbumsTitlesAreUpdatedAndAlbumsAreSortedCorrectly() async throws {
        var favouriteAlbum = AlbumEntity(id: 1, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .favourite)
        var gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        var rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:01:04Z".date)
        let userAlbum2 = AlbumEntity(id: 5, name: "Album 2", coverNode: NodeEntity(handle: 4),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:02:04Z".date)
        let userAlbum3 = AlbumEntity(id: 6, name: "Other Album 1", coverNode: NodeEntity(handle: 5),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:03:04Z".date)
        let userAlbum4 = AlbumEntity(id: 7, name: "Other Album 4", coverNode: NodeEntity(handle: 6),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:04:04Z".date)
        let userAlbum5 = AlbumEntity(id: 8, name: "Album 5", coverNode: NodeEntity(handle: 7),
                                     count: 1, type: .user, creationTime: try "2022-12-31T22:05:04Z".date)
        let useCase = MockAlbumListUseCase(albums: [favouriteAlbum, gifAlbum, rawAlbum,
                                                    userAlbum1, userAlbum2, userAlbum3, userAlbum4, userAlbum5])
        // Update titles to expected
        favouriteAlbum.name = Strings.Localizable.CameraUploads.Albums.Favourites.title
        gifAlbum.name = Strings.Localizable.CameraUploads.Albums.Gif.title
        rawAlbum.name = Strings.Localizable.CameraUploads.Albums.Raw.title
        let sut = albumListViewModel(usecase: useCase)
                
        let result = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
         
        XCTAssertEqual(result, [
            favouriteAlbum,
            gifAlbum,
            rawAlbum,
            userAlbum5,
            userAlbum4,
            userAlbum3,
            userAlbum2,
            userAlbum1
        ])
    }
    
    @MainActor
    func testLoadAlbums_onAlbumsLoadedFinished_shouldLoadSetToFalse() async throws {
        let sut = albumListViewModel()
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        XCTAssertFalse(sut.shouldLoad)
    }
    
    @MainActor
    func testHasCustomAlbum_whenUserLoadAlbums_shouldReturnTrue() async throws {
        let rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user)
        let mockAlbumUseCase = MockAlbumListUseCase(albums: [rawAlbum, userAlbum1])
                                     
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: mockAlbumUseCase, photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        XCTAssertTrue(photoAlbumContainerViewModel.shouldShowSelectBarButton)
    }
    
    @MainActor
    func testHasCustomAlbum_whenUserCreateNewAlbum_shouldReturnTrue() async {
        
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let tracker = MockTracker()
        let sut = albumListViewModel(
            tracker: tracker,
            photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        sut.createUserAlbum(with: "userAlbum")
        await sut.createAlbumTask?.value
        XCTAssertTrue(photoAlbumContainerViewModel.shouldShowSelectBarButton)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.createAlbumDialogButtonPressedEvent])
    }
    
    @MainActor
    func testCreateUserAlbum_whenUserCreatingAnAlbum_setShouldShowSelectBarButtonToFalse() async throws {
        let newAlbumName = "New Album"
        let newUserAlbum = AlbumEntity(id: 1, name: newAlbumName, coverNode: nil,
                                       count: 0, type: .user, modificationTime: try "2023-01-16T11:01:04Z".date)
        let useCase = MockAlbumListUseCase(albums: [], createdUserAlbums: [newAlbumName: newUserAlbum])
        
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let tracker = MockTracker()
        let sut = albumListViewModel(
            usecase: useCase, 
            tracker: tracker,
            photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        sut.createUserAlbum(with: newAlbumName)
        XCTAssertTrue(photoAlbumContainerViewModel.disableSelectBarButton)
        await sut.createAlbumTask?.value
        XCTAssertFalse(photoAlbumContainerViewModel.disableSelectBarButton)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.createAlbumDialogButtonPressedEvent])
    }
    
    @MainActor
    func testNewAlbumName_whenAlbumContainsNoNewAlbum() async {
        let sut = albumListViewModel()
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
    }
    
    @MainActor
    func testNewAlbumName_whenAlbumContainsNewAlbum() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        let result = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " \("(1)")")
    }
    
    @MainActor
    func testNewAlbumName_whenAlbumContainsSomeNewAlbums_shouldReturnTheCorrectSuffix() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let newAlbum1 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (1)")
        
        let newAlbum3 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (3)")
        
        let newAlbum4 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + "Some Random name")
        
        let useCase = MockAlbumListUseCase(albums: [newAlbum4, newAlbum, newAlbum1, newAlbum3])
        let sut = albumListViewModel(usecase: useCase)
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        let newAlbumNameShouldBe = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (2)"
        
        XCTAssertEqual(sut.newAlbumName(), newAlbumNameShouldBe)
    }
    
    @MainActor
    func testNewAlbumName_whenAlbumContainsSomeNewAlbumsButNotNewAlbum_shouldReturnNewAlbum() async {
        let newAlbum1 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (1)")
        
        let newAlbum3 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " (3)")
        
        let newAlbum4 = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + "Some Random name")
        
        let useCase = MockAlbumListUseCase(albums: [newAlbum4, newAlbum1, newAlbum3])
        let sut = albumListViewModel(usecase: useCase)
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        let newAlbumNameShouldBe = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        
        XCTAssertEqual(sut.newAlbumName(), newAlbumNameShouldBe)
    }
    
    @MainActor
    func testNewAlbumNamePlaceholderText_whenAlbumContainsNewAlbum_shouldReturnCounterSuffix() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        _ = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        sut.showCreateAlbumAlert = true
        
        XCTAssertEqual(sut.alertViewModel.placeholderText, "New album (1)")
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsNil_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?(nil))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsEmpty_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?(""))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsSpaces_returnsError() {
        let sut = albumListViewModel()
        XCTAssertNotNil(sut.alertViewModel.validator?("      "))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsValidButWithWhiteSpaces_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?("  userAlbum    "))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsValid_returnsNil() {
        let sut = albumListViewModel()
        XCTAssertNil(sut.alertViewModel.validator?("userAlbum"))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameContainsInvalidChars_returnsErrorMessage() {
        let sut = albumListViewModel()
        XCTAssertNotNil(sut.alertViewModel.validator?("userAlbum:/;"))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsSameAsExistingUserAlbum_returnsErrorMessage() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: "userAlbum")
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = albumListViewModel(usecase: useCase)
        let result = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        XCTAssertEqual(result?.count, 1)
        XCTAssertNotNil(sut.alertViewModel.validator?(newAlbum.name))
    }
    
    @MainActor
    func testValidateAlbum_whenAlbumNameIsSameAsExistingSystemAlbum_returnsErrorMessage() async {
        let newSysAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                      coverNode: NodeEntity(handle: AlbumIdEntity.favourite.rawValue), count: 0, type: .favourite)
        let useCase = MockAlbumListUseCase(albums: [newSysAlbum])
        let sut = albumListViewModel(usecase: useCase)
        let result = await withThrowingTaskGroup(of: Void.self, returning: [AlbumEntity]?.self) { taskGroup in
            taskGroup.addTask { try await sut.monitorAlbums() }
            return await sut.$albums.dropFirst().values.first { @Sendable _ in true }
        }
        
        XCTAssertEqual(result?.count, 1)
        XCTAssertNotNil(sut.alertViewModel.validator?(newSysAlbum.name))
    }
    
    @MainActor
    func testOnAlbumContentAdded_whenContentAddedInNewAlbum_shouldReloadAlbums() async {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)

        let sampleAlbum = AlbumEntity(id: 1, name: "hello", coverNode: nil, count: 0, type: .user)
        let nodes = [NodeEntity(handle: 1)]
        sut.onNewAlbumContentAdded(sampleAlbum, photos: nodes)
        
        XCTAssertEqual(sut.newAlbumContent?.album, sampleAlbum)
        XCTAssertEqual(sut.newAlbumContent?.photos, nodes)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.addItemsToNewAlbumButtonEvent])
    }
    
    @MainActor
    func testValidateAlbum_withSystemAlbumNames_returnsErrorMessage() {
        let reservedNames = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                             Strings.Localizable.CameraUploads.Albums.Gif.title,
                             Strings.Localizable.CameraUploads.Albums.Raw.title,
                             Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                             Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]
        let sut = albumListViewModel()
        reservedNames.forEach { name in
            XCTAssertNotNil(sut.alertViewModel.validator?(name))
        }
    }
    
    @MainActor
    func testColumns_sizeConfigurationsChangesReturnCorrectColumns() {
        let sut = albumListViewModel()
        XCTAssertEqual(sut.columns(horizontalSizeClass: .compact).count, 3)
        XCTAssertEqual(sut.columns(horizontalSizeClass: nil).count, 3)
        XCTAssertEqual(sut.columns(horizontalSizeClass: .regular).count, 5)
    }
    
    @MainActor
    func testNavigateToNewAlbum_onNewAlbumContentAdded_shouldNavigateToAlbumContentIfSet() {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        let userAlbum = AlbumEntity(id: 1, name: "User", coverNode: nil, count: 0, type: .user)
        let newAlbumPhotos = [NodeEntity(name: "a.jpg", handle: 1, modificationTime: Date.distantFuture),
                              NodeEntity(name: "b.jpg", handle: 2, modificationTime: Date.distantPast)]
        
        let modifiedAlbum = AlbumEntity(id: 1, name: "User", coverNode: newAlbumPhotos.first, count: 2, type: .user)
        
        sut.onNewAlbumContentAdded(userAlbum, photos: newAlbumPhotos)
        sut.navigateToNewAlbum()
        
        XCTAssertEqual(sut.album, modifiedAlbum)
        XCTAssertEqual(sut.newAlbumContent?.photos, newAlbumPhotos)
        XCTAssertEqual(sut.album?.count, newAlbumPhotos.count)
        XCTAssertEqual(sut.album?.coverNode, newAlbumPhotos.first)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.addItemsToNewAlbumButtonEvent])
    }
    
    @MainActor
    func testNavigateToNewAlbum_onNewAlbumContentAddedNotCalled_shouldNotNavigate() {
        let sut = albumListViewModel()
        
        sut.navigateToNewAlbum()
        XCTAssertNil(sut.album)
        XCTAssertNil(sut.newAlbumContent)
    }
    
    @MainActor
    func testOnAlbumTap_whenUserTap_shouldSetCorrectValues() {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        
        sut.onAlbumTap(gifAlbum)
        XCTAssertNil(sut.albumCreationAlertMsg)
        XCTAssertEqual(sut.album, gifAlbum)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                gifAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    @MainActor
    func testOnAlbumTap_notInEditMode_shouldSendSelectedEvent() {
        let userAlbum = AlbumEntity(id: 5, type: .user,
                                    metaData: AlbumMetaDataEntity(
                                        imageCount: 6,
                                        videoCount: 8))
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        sut.onAlbumTap(userAlbum)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                userAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    @MainActor
    func testOnCreateAlbum_whenIsEditModeActive_shouldReturnFalseForShowCreateAlbumAlert() {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        sut.selection.editMode = .active
        XCTAssertFalse(sut.showCreateAlbumAlert)
        sut.onCreateAlbum()
        XCTAssertFalse(sut.showCreateAlbumAlert)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.createNewAlbumDialogEvent])
    }
    
    @MainActor
    func testOnCreateAlbum_whenIsEditModeNotActive_shouldToggleShowCreateAlbumAlert() {
        let tracker = MockTracker()
        let sut = albumListViewModel(tracker: tracker)
        
        XCTAssertFalse(sut.showCreateAlbumAlert)
        sut.onCreateAlbum()
        XCTAssertTrue(sut.showCreateAlbumAlert)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DIContainer.createNewAlbumDialogEvent])
    }
    
    @MainActor
    func testAlbumNames_whenExistingAlbumNamesNeeded_shouldReturnAlbumNames() async {
        let album1 = AlbumEntity(id: 1, name: "Hey there", coverNode: nil, count: 0, type: .user)
        let album2 = AlbumEntity(id: 1, name: "", coverNode: nil, count: 0, type: .user)
        let album3 = AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite)
        
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: [album1, album2, album3]))
        let task = Task { try await sut.monitorAlbums() }
        _ = await sut.$albums.dropFirst().values.first { @Sendable albums in albums.isNotEmpty  }
        task.cancel()
        
        XCTAssertEqual(sut.albumNames.sorted(), ["Hey there", "", "Favourites"].sorted())
    }
    
    @MainActor
    func testReloadUpdates_onAlbumsUpdateEmitted_shouldReloadAlbums() {
        let albums = [AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                  count: 1, type: .user)]
        let albumsUpdatedPublisher = PassthroughSubject<Void, Never>()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums,
                                                                   albumsUpdatedPublisher: albumsUpdatedPublisher.eraseToAnyPublisher()))
        
        let task = Task { try await sut.monitorAlbums() }
        
        XCTAssertTrue(sut.albums.isEmpty)
        
        let exp = expectation(description: "should retrieve albums")
        sut.$albums
            .dropFirst()
            .sink {
                XCTAssertEqual($0, albums)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumsUpdatedPublisher.send()
        wait(for: [exp], timeout: 2.0)
        task.cancel()
    }
    
    @MainActor
    func testShowDeleteAlbumAlert_whenUserTapOnDeleteButton_shouldSetShowDeleteAlbumAlertToTrue() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumAlertType)
        photoAlbumContainerViewModel.showDeleteAlbumAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .deleteAlbum)
    }
    
    @MainActor
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedSuccessfully_shouldDeleteMultipleAlbums() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums),
                                     albumModificationUseCase: MockAlbumModificationUseCase(albums: albums),
                                     photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        
        await sut.deleteAlbumTask?.value
        
        let targetMsg = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(albums.count)
        
        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: UIImage.hudMinus))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    @MainActor
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedSuccessfully_shouldDeleteSingleAlbum() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(albums: albums),
                                     albumModificationUseCase: MockAlbumModificationUseCase(albums: albums),
                                     photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        await sut.deleteAlbumTask?.value
        
        let targetMsg = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(albums.count)
        
        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: UIImage.hudMinus))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    @MainActor
    func testOnAlbumListDeleteConfirm_whenAlbumDeletedFailed_shouldDoNothing() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(usecase: MockAlbumListUseCase(), photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        sut.selection.setSelectedAlbums(albums)
        
        XCTAssertNil(sut.albumHudMessage)
        
        sut.onAlbumListDeleteConfirm()
        await sut.deleteAlbumTask?.value
        
        XCTAssertNil(sut.albumHudMessage)
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    @MainActor
    func testNumOfSelectedAlbums_onAlbumSelectionChanged_shouldSetIsAlbumSelected() {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user)]
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        XCTAssertFalse(photoAlbumContainerViewModel.isAlbumsSelected)
        
        sut.selection.setSelectedAlbums(albums)
        XCTAssertTrue(photoAlbumContainerViewModel.isAlbumsSelected)
    }
    
    @MainActor
    func testShowDeleteAlbumAlert_whenUserTapDeleteButton_shouldSetShowAlertToTrueAndAlertTypeToDeleteAlbum() async {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        photoAlbumContainerViewModel.showDeleteAlbumAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .deleteAlbum)
    }
    
    @MainActor
    func testIsExportedAlbumSelected_onExportedAlbumSelected_shouldSetIsExportedAlbumSelected() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isExportedAlbumSelected)
        let exportedUserAlbum = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        sut.selection.setSelectedAlbums([exportedUserAlbum])
        XCTAssertTrue(photoAlbumContainerViewModel.isExportedAlbumSelected)
    }
    
    @MainActor
    func testIsAllExportedAlbumSelected_onExportedAlbumSelected_shouldSetisAllExportedAlbumSelectedToTrue() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
        let exportedUserAlbum1 = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        let exportedUserAlbum2 = AlbumEntity(id: 4, type: .user, sharedLinkStatus: .exported(true))
        sut.selection.setSelectedAlbums([exportedUserAlbum1, exportedUserAlbum2])
        XCTAssertTrue(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
    }
    
    @MainActor
    func testIsAllExportedAlbumSelected_onExportedAlbumSelected_shouldSetisAllExportedAlbumSelectedToFalse() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
        let exportedUserAlbum1 = AlbumEntity(id: 5, type: .user, sharedLinkStatus: .exported(true))
        let normalAlbum = AlbumEntity(id: 4, type: .user)
        sut.selection.setSelectedAlbums([exportedUserAlbum1, normalAlbum])
        XCTAssertFalse(photoAlbumContainerViewModel.isOnlyExportedAlbumsSelected)
    }
    
    @MainActor
    func testShowAlbumRemoveShareLinkAlert_whenUserTapRemoveLinkButton_shouldSetShowAlertToTrueAndAlertTypeToRemoveAlbumShareLink() async {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        photoAlbumContainerViewModel.showRemoveAlbumLinksAlert = true
        XCTAssertNotNil(sut.albumAlertType)
        XCTAssertEqual(sut.albumAlertType, .removeAlbumShareLink)
    }
    
    @MainActor
    func testOnShareLinkRemoveConfirm_whenAllAlbumShareLinkRemoveSuccessfully_shouldShowMultipleAlbumLinkDeleteHudMessage() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user)]

        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(shareAlbumUseCase: MockShareAlbumUseCase(successfullyRemoveSharedAlbumLinkIds: [HandleEntity(1), HandleEntity(2)]), photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        XCTAssertNil(sut.albumHudMessage)
        sut.onAlbumShareLinkRemoveConfirm(albums)
        await sut.albumRemoveShareLinkTask?.value

        let targetMsg = Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(albums.count)

        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: UIImage.hudSuccess))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    @MainActor
    func testOnShareLinkRemoveConfirm_whenSomeAlbumShareLinkRemoveSuccessfully_shouldShowSingleAlbumLinkDeleteHudMessage() async {
        let albums = [AlbumEntity(id: HandleEntity(1), name: "ABC", coverNode: nil, count: 1, type: .user),
                      AlbumEntity(id: HandleEntity(2), name: "DEF", coverNode: nil, count: 2, type: .user),
                      AlbumEntity(id: HandleEntity(3), name: "GHI", coverNode: nil, count: 4, type: .user)]
        
        let succesfullyDeleteAlbum = albums[0]

        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(shareAlbumUseCase: MockShareAlbumUseCase(successfullyRemoveSharedAlbumLinkIds: [succesfullyDeleteAlbum.id]), photoAlbumContainerViewModel: photoAlbumContainerViewModel)

        XCTAssertNil(sut.albumHudMessage)
        sut.onAlbumShareLinkRemoveConfirm(albums)
        await sut.albumRemoveShareLinkTask?.value

        let targetMsg = Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1)

        XCTAssertEqual(sut.albumHudMessage, AlbumHudMessage(message: targetMsg, icon: UIImage.hudSuccess))
        XCTAssertFalse(photoAlbumContainerViewModel.editMode.isEditing)
    }
    
    @MainActor
    func testShowAlbumLinks_onShowShareAlbumsFired_shouldTrigger() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        XCTAssertFalse(sut.showShareAlbumLinks)
        
        photoAlbumContainerViewModel.showShareAlbumLinks = true
        
        XCTAssertTrue(sut.showShareAlbumLinks)
    }
    
    @MainActor
    func testSelectedUserAlbums_onAlbumsSelected_shouldOnlyReturnUseAlbums() {
        let sut = albumListViewModel()
        XCTAssertTrue(sut.selectedUserAlbums.isEmpty)
        
        let userAlbum = AlbumEntity(id: 5, type: .user)
        sut.selection.setSelectedAlbums([AlbumEntity(id: 7, type: .favourite), userAlbum])
        XCTAssertEqual(sut.selectedUserAlbums, [userAlbum])
    }
    
    @MainActor
    func testSetEditModeToInactive_onCalled_shouldSetContainerViewModelEditModeToInactive() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        photoAlbumContainerViewModel.editMode = .active
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        sut.setEditModeToInactive()
        XCTAssertEqual(photoAlbumContainerViewModel.editMode, .inactive)
    }
    
    @MainActor
    func testOnViewDisappear_editModeActiveAndToolbarShown_shouldSetEditModeToInactiveAndToolbarShouldNotShow() {
        let photoAlbumContainerViewModel = PhotoAlbumContainerViewModel()
        photoAlbumContainerViewModel.editMode = .active
        let sut = albumListViewModel(photoAlbumContainerViewModel: photoAlbumContainerViewModel)
        
        sut.onViewDisappear()
        
        XCTAssertEqual(photoAlbumContainerViewModel.editMode, .inactive)
        XCTAssertFalse(photoAlbumContainerViewModel.showToolbar)
    }
        
    // MARK: - Helpers
    
    private func alertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                   placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                   affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                   message: nil)
    }
    
    @MainActor
    private func albumListViewModel(
        usecase: some AlbumListUseCaseProtocol = MockAlbumListUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        shareAlbumUseCase: some ShareAlbumUseCaseProtocol = MockShareAlbumUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        photoAlbumContainerViewModel: PhotoAlbumContainerViewModel? = nil
    ) -> AlbumListViewModel {
        AlbumListViewModel(
            usecase: usecase,
            albumModificationUseCase: albumModificationUseCase,
            shareAlbumUseCase: shareAlbumUseCase,
            tracker: tracker,
            alertViewModel: alertViewModel(),
            photoAlbumContainerViewModel: photoAlbumContainerViewModel
        )
    }
}

extension PhotoAlbumContainerViewModel {
    convenience init() {
        self.init(tracker: MockTracker())
    }
}
