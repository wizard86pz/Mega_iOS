
#import "MEGABaseRequestDelegate.h"

@interface MEGARenameRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
