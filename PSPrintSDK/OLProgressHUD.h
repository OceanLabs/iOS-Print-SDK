//
//  SVProgressHUD.h
//  SVProgressHUD, https://github.com/TransitApp/SVProgressHUD
//
//  Copyright (c) 2011-2014 Sam Vermette and contributors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000

#define UI_APPEARANCE_SELECTOR

#endif

extern NSString * const OLProgressHUDDidReceiveTouchEventNotification;
extern NSString * const OLProgressHUDDidTouchDownInsideNotification;
extern NSString * const OLProgressHUDWillDisappearNotification;
extern NSString * const OLProgressHUDDidDisappearNotification;
extern NSString * const OLProgressHUDWillAppearNotification;
extern NSString * const OLProgressHUDDidAppearNotification;

extern NSString * const OLProgressHUDStatusUserInfoKey;

typedef NS_ENUM(NSInteger, OLProgressHUDStyle) {
    OLProgressHUDStyleLight,        // default style, white HUD with black text, HUD background will be blurred on iOS 8 and above
    OLProgressHUDStyleDark,         // black HUD and white text, HUD background will be blurred on iOS 8 and above
    OLProgressHUDStyleCustom        // uses the fore- and background color properties
};

typedef NS_ENUM(NSUInteger, OLProgressHUDMaskType) {
    OLProgressHUDMaskTypeNone = 1,  // default mask type, allow user interactions while HUD is displayed
    OLProgressHUDMaskTypeClear,     // don't allow user interactions
    OLProgressHUDMaskTypeBlack,     // don't allow user interactions and dim the UI in the back of the HUD, as on iOS 7 and above
    OLProgressHUDMaskTypeGradient   // don't allow user interactions and dim the UI with a a-la alert view background gradient, as on iOS 6
};

typedef NS_ENUM(NSUInteger, OLProgressHUDAnimationType) {
    OLProgressHUDAnimationTypeFlat,     // default animation type, custom flat animation (indefinite animated ring)
    OLProgressHUDAnimationTypeNative    // iOS native UIActivityIndicatorView
};

@interface OLProgressHUD : UIView

#pragma mark - Customization

@property (assign, nonatomic) OLProgressHUDStyle defaultStyle UI_APPEARANCE_SELECTOR;                   // default is OLProgressHUDStyleLight
@property (assign, nonatomic) OLProgressHUDMaskType defaultMaskType UI_APPEARANCE_SELECTOR;             // default is OLProgressHUDMaskTypeNone
@property (assign, nonatomic) OLProgressHUDAnimationType defaultAnimationType UI_APPEARANCE_SELECTOR;   // default is OLProgressHUDAnimationTypeFlat
@property (assign, nonatomic) CGFloat ringThickness UI_APPEARANCE_SELECTOR;           // default is 2 pt
@property (assign, nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;            // default is 14 pt
@property (assign, nonatomic) UIOffset offsetFromCenter UI_APPEARANCE_SELECTOR;       // default is 0, 0

@property (strong, nonatomic) UIFont *font UI_APPEARANCE_SELECTOR;                    // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
@property (strong, nonatomic) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;        // default is [UIColor whiteColor]
@property (strong, nonatomic) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;        // default is [UIColor blackColor]
@property (strong, nonatomic) UIImage *infoImage UI_APPEARANCE_SELECTOR;              // default is the bundled info image provided by Freepik
@property (strong, nonatomic) UIImage *successImage UI_APPEARANCE_SELECTOR;           // default is the bundled success image provided by Freepik
@property (strong, nonatomic) UIImage *errorImage UI_APPEARANCE_SELECTOR;             // default is the bundled error image provided by Freepik
@property (strong, nonatomic) UIView *viewForExtension UI_APPEARANCE_SELECTOR;        // default is nil, only used if #define OL_APP_EXTENSIONS is set

+ (void)setDefaultStyle:(OLProgressHUDStyle)style;                  // default is OLProgressHUDStyleLight
+ (void)setDefaultMaskType:(OLProgressHUDMaskType)maskType;         // default is OLProgressHUDMaskTypeNone
+ (void)setDefaultAnimationType:(OLProgressHUDAnimationType)type;   // default is OLProgressHUDAnimationTypeFlat
+ (void)setRingThickness:(CGFloat)width;                            // default is 2 pt
+ (void)setCornerRadius:(CGFloat)cornerRadius;                      // default is 14 pt
+ (void)setFont:(UIFont*)font;                                      // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setForegroundColor:(UIColor*)color;                         // default is [UIColor blackColor], only used for OLProgressHUDStyleCustom
+ (void)setBackgroundColor:(UIColor*)color;                         // default is [UIColor whiteColor], only used for OLProgressHUDStyleCustom
+ (void)setInfoImage:(UIImage*)image;                               // default is the bundled info image provided by Freepik
+ (void)setSuccessImage:(UIImage*)image;                            // default is the bundled success image provided by Freepik
+ (void)setErrorImage:(UIImage*)image;                              // default is the bundled error image provided by Freepik
+ (void)setViewForExtension:(UIView*)view;                          // default is nil, only used if #define OL_APP_EXTENSIONS is set


#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use show and setDefaultMaskType: instead.")));
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showWithStatus: and setDefaultMaskType: instead.")));

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showProgress: and setDefaultMaskType: instead.")));
+ (void)showProgress:(float)progress status:(NSString*)status;
+ (void)showProgress:(float)progress status:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showProgress: and setDefaultMaskType: instead.")));

+ (void)setStatus:(NSString*)status; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses the HUD a little bit later
+ (void)showInfoWithStatus:(NSString*)status;
+ (void)showInfoWithStatus:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showInfoWithStatus: and setDefaultMaskType: instead.")));
+ (void)showSuccessWithStatus:(NSString*)status;
+ (void)showSuccessWithStatus:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showSuccessWithStatus: and setDefaultMaskType: instead.")));
+ (void)showErrorWithStatus:(NSString*)status;
+ (void)showErrorWithStatus:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showErrorWithStatus: and setDefaultMaskType: instead.")));

// shows a image + status, use 28x28 white PNGs
+ (void)showImage:(UIImage*)image status:(NSString*)status;
+ (void)showImage:(UIImage*)image status:(NSString*)status maskType:(OLProgressHUDMaskType)maskType __attribute__((deprecated("Use showImage: and setDefaultMaskType: instead.")));

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity; // decrease activity count, if activity count == 0 the HUD is dismissed
+ (void)dismiss;
+ (void)dismissWithDelay:(NSTimeInterval)delay; // delayes the dismissal

+ (BOOL)isVisible;


@end

