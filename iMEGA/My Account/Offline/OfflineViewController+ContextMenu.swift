import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension OfflineViewController: DisplayMenuDelegate {
    // MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity {
        return CMConfigEntity(menuType: .menu(type: .display),
                              viewMode: isListViewModeSelected() ? .list : .thumbnail,
                              sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: currentOfflinePath)).megaSortOrderType.toSortOrderEntity(),
                              isOfflineFolder: true)
    }
    
    @objc func setNavigationBarButtons() {
        contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
        
        contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                               menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
        
        contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
        
        navigationItem.rightBarButtonItems = [contextBarButtonItem]
    }
    
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            changeEditingModeStatus()
        case .thumbnailView, .listView:
            if isListViewModeSelected() && action == .thumbnailView || !isListViewModeSelected() && action == .listView {
                changeViewModePreference()
            }
        default: break
        }
        
        if needToRefreshMenu {
            setNavigationBarButtons()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: currentOfflinePath)
        nodesSortTypeHasChanged()
        setNavigationBarButtons()
    }
}
