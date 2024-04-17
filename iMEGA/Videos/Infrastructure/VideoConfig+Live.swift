import MEGADesignToken
import SwiftUI
import Video

extension VideoConfig {
    
    static func live(isDesignTokenEnabled: Bool) -> VideoConfig { VideoConfig(
        videoListAssets: VideoConfig.VideoListAssets(
            noResultVideoImage: UIImage.noResultsVideo
        ),
        rowAssets: VideoConfig.RowAssets(
            favoriteImage: UIImage.favouriteThumbnail,
            playImage: UIImage.blackPlayButton,
            publicLinkImage: UIImage.linked,
            moreImage: UIImage.moreList,
            addPlaylistImage: UIImage.navigationbarAdd,
            rectangleVideoStackPlaylistImage: UIImage.rectangleVideoStack,
            favouritePlaylistThumbnailImage: UIImage.favouritePlaylistThumbnail,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: UIImage.redSmall,
                orangeImage: UIImage.orangeSmall,
                yellowImage: UIImage.yellowSmall,
                greenImage: UIImage.greenSmall,
                blueImage: UIImage.blueSmall,
                purpleImage: UIImage.purpleSmall,
                greyImage: UIImage.greySmall
            )
        ),
        colorAssets: VideoConfig.ColorAssets(
            primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary,
            secondaryTextColor: isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : Color.secondary,
            primaryIconColor: isDesignTokenEnabled ? TokenColors.Icon.primary.swiftUI : Color.videoToolbarIconEnabled,
            secondaryIconColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : Color.secondary,
            pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear,
            whiteColor: isDesignTokenEnabled ? TokenColors.Text.onColor.swiftUI : Color.white,
            durationTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.white,
            tabActiveIndicatorColor: isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : MEGAAppColor.Red._F30C14.color,
            tabInactiveIndicatorColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.clear,
            tabInactiveTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.videosTabTitle.swiftUI,
            addPlaylistButtonTextColor: isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : Color.white,
            addPlaylistButtonBackgroundColor: isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI : Color.videoPlaylistAddButtonBackground,
            toolbarBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.mainBar,
            navigationBgColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.mainBar,
            emptyFavoriteThumbnailBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : Color.videoPlaylistEmptyFavoriteThumbnailBackground,
            emptyFavoriteThumbnaillImageForegroundColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : Color.videoPlaylistEmptyFavoriteThumbnaillImageForeground,
            videoThumbnailImageViewPlaceholderBackgroundColor: MEGAAppColor.Videos.videoThumbnailImageViewPlaceholderBackgroundColor.color,
            videoThumbnailDurationTextBackgroundColor: MEGAAppColor.Videos.videoThumbnailDurationTextBackgroundColor.color,
            disabledColor: isDesignTokenEnabled ? TokenColors.Text.disabled.swiftUI : Color.videoToolbarIconDisabled
        ),
        toolbarAssets: VideoConfig.ToolbarAssets(
            offlineImage: UIImage.offline,
            linkImage: UIImage.link,
            saveToPhotosImage: UIImage.saveToPhotos,
            hudMinusImage: UIImage.hudMinus,
            moreListImage: UIImage.moreList
        ),
        recentlyWatchedAssets: RecentlyWatchedAssets(
            emptyView: .init(
                color: .init(
                    pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear,
                    textColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary,
                    iconColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : Color.secondary
                )
            ),
            listView: .init(
                header: .init(
                    color: .init(
                        primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary,
                        pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear
                    )
                ),
                cell: .init(
                    color: .init(
                        primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.black000000.swiftUI,
                        secondaryTextColor: isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : UIColor.gray515151.swiftUI,
                        secondaryIconColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : UIColor.gray848484.swiftUI,
                        durationTextColor: isDesignTokenEnabled ? TokenColors.Button.primary.swiftUI : Color.white,
                        durationTextBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.blur.swiftUI : Color.black.opacity(0.2),
                        pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear,
                        progressBarActiveColor: isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : UIColor.redF30C14.swiftUI,
                        progressBarBackgroundColor: isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : UIColor.gray949494.swiftUI
                    )
                )
            )
        ),
        playlistContentAssets: PlaylistContentAssets(
            headerView: .init(
                image: .init(
                    dotSeparatorImage: UIImage(systemName: "circle.fill")!,
                    publicLinkImage: UIImage.linked,
                    addButtonImage: UIImage(systemName: "plus")!,
                    playButtonImage: UIImage(systemName: "play.fill")!
                ),
                color: .init(
                    pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.mainBar,
                    thumbnailBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : Color.videoPlaylistContentThumbnailBackground,
                    primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.black000000.swiftUI,
                    secondaryTextColor: isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : UIColor.gray515151.swiftUI,
                    secondaryIconColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : UIColor.gray848484.swiftUI,
                    buttonTintColor: isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI : Color.videoPlaylistAddButtonBackground
                )
            )
        )
    )}
}
