//
//  MPFlipViewController.h
//  MPFlipViewController
//
//  Created by Mark Pospesel on 6/4/12.
//  Copyright (c) 2012 Mark Pospesel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLTransitionEnumerations.h"

enum {
    OLFlipViewControllerOrientationHorizontal = 0,
    OLFlipViewControllerOrientationVertical = 1
};
typedef NSInteger OLFlipViewControllerOrientation;

/*enum {
    OLFlipViewControllerSpineLocationNone = 0, // Undefined
    OLFlipViewControllerSpineLocationMin = 1,  // Spine is at Left or Top
    OLFlipViewControllerSpineLocationMid = 2,  // Spine is in middle
    OLFlipViewControllerSpineLocationMax = 3   // Spine is at Right or Bottom
};
typedef NSInteger OLFlipViewControllerSpineLocation;*/

enum {
    OLFlipViewControllerDirectionForward,
    OLFlipViewControllerDirectionReverse
};
typedef NSInteger OLFlipViewControllerDirection; // For 'OLFlipViewControllerOrientationHorizontal', 'forward' is right-to-left, like pages in a book. For 'OLFlipViewControllerOrientationVertical', bottom-to-top, like pages in a wall calendar.

@protocol OLFlipViewControllerDelegate, OLFlipViewControllerDataSource;

@interface OLFlipViewController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic, readonly) OLFlipViewControllerOrientation orientation; // horizontal or vertical
@property (nonatomic, readonly) UIViewController *viewController;
@property (nonatomic, readonly) NSArray *gestureRecognizers;
@property (nonatomic, assign) id <OLFlipViewControllerDelegate> delegate;
@property (nonatomic, assign) id <OLFlipViewControllerDataSource> dataSource; // If nil, user gesture-driven navigation will be disabled.

// designated initializer
- (id)initWithOrientation:(OLFlipViewControllerOrientation)orientation;

// flip to a new page
- (void)setViewController:(UIViewController *)viewController direction:(OLFlipViewControllerDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end

@protocol OLFlipViewControllerDelegate<NSObject>

@optional
// handle this to be notified when page flip animations have finished
- (void)flipViewController:(OLFlipViewController *)flipViewController didFinishAnimating:(BOOL)finished previousViewController:(UIViewController *)previousViewController transitionCompleted:(BOOL)completed;

// handle this and return the desired orientation (horizontal or vertical) for the new interface orientation
// called when OLFlipViewController handles willRotateToInterfaceOrientation:duration: callback
- (OLFlipViewControllerOrientation)flipViewController:(OLFlipViewController *)flipViewController orientationForInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

@protocol OLFlipViewControllerDataSource 
@required

- (UIViewController *)flipViewController:(OLFlipViewController *)flipViewController viewControllerBeforeViewController:(UIViewController *)viewController; // get previous page, or nil for none
- (UIViewController *)flipViewController:(OLFlipViewController *)flipViewController viewControllerAfterViewController:(UIViewController *)viewController; // get next page, or nil for none

@end

// Notifications
// All of the following notifications have an `object' that is the sending OLFipViewController.

// The following notification has a userInfo key "OLAnimationFinished" with an NSNumber (bool, YES/NO) value,
// an "OLTransitionCompleted" key with an NSNumber (bool, YES/NO) value,
// an "OLPreviousController" key with a UIViewController value, and
// an "OLNewController" key with a UIViewController value (will be NSNull for rubber-banding past first/last controller)
#define OLAnimationFinishedKey @"OLAnimationFinished"
#define OLTransitionCompletedKey @"OLTransitionCompleted"
#define OLPreviousControllerKey @"OLPreviousController"
#define OLNewControllerKey @"OLNewController"
extern NSString *OLFlipViewControllerDidFinishAnimatingNotification;

