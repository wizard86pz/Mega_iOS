
#import "MyAccountHallTableViewCell.h"

#import "MEGA-Swift.h"

@implementation MyAccountHallTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupCell];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupCell];
}

#pragma mark - Private

- (void)setupCell {
    self.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    
    self.detailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.pendingView.backgroundColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    self.pendingLabel.textColor = UIColor.whiteColor;
}


@end
