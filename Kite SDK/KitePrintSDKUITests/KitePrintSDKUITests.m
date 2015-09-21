//
//  KitePrintSDKUITests.m
//  KitePrintSDKUITests
//
//  Created by Konstadinos Karayannis on 9/2/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLKitePrintSDK.h"

@interface KitePrintSDKUITests : XCTestCase

@end

@implementation KitePrintSDKUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{@"OL_KITE_UI_TEST" : @"1", @"TEST_API_KEY" : @"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4"};
    [app launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCaseCheckout{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"Print Photos at Remote URLs"] tap];
    [app.alerts[@"Remote URLS"].collectionViews.buttons[@"OK"] tap];
    
    XCUIElementQuery *collectionViewsQuery = app.collectionViews;
    XCUIElement *element = collectionViewsQuery.staticTexts[@"Phone Cases"];
    
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:exists evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:50 handler:nil];
    
    [element tap];
    [collectionViewsQuery.staticTexts[@"iPhone 6+"] tap];
    [app.navigationBars[@"iPhone 6+"].buttons[@"Next"] tap];
    [app.navigationBars[@"Reposition the Photo"].buttons[@"Next"] tap];
    [app.tables.buttons[@"button apple pay"] tap];
    [app.buttons[@"Pay"] tap];
}

- (void)testSquarePrintsCheckout{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"Print Photos at Remote URLs"] tap];
    [app.alerts[@"Remote URLS"].collectionViews.buttons[@"OK"] tap];
    
    XCUIElementQuery *collectionViewsQuery = app.collectionViews;
    [[collectionViewsQuery.cells.otherElements containingType:XCUIElementTypeStaticText identifier:@"Tough Phone Cases"].activityIndicators[@"In progress"] swipeUp];
    
    XCUIElement *element = [[[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element;
    
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:exists evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:50 handler:nil];
    
    [element swipeUp];
    [collectionViewsQuery.staticTexts[@"Prints"] tap];
    [collectionViewsQuery.staticTexts[@"Mini squares"] tap];
    [app.navigationBars[@"Mini squares"].buttons[@"Next"] tap];
    [app.navigationBars[@"Choose Photos"].buttons[@"Next"] tap];
    [app.navigationBars[@"4 / 23"].buttons[@"Confirm"] tap];
    [app.alerts[@"You've selected 4 photos."].collectionViews.buttons[@"Print these"] tap];
    [app.tables.buttons[@"button apple pay"] tap];
    [app.buttons[@"Pay"] tap];
}

- (void)testPhotobookCheckout{
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"Print Photos at Remote URLs"] tap];
    [app.alerts[@"Remote URLS"].collectionViews.buttons[@"OK"] tap];
    
    XCUIElement *element = [[[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element;
    
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:exists evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:50 handler:nil];
    
    [element swipeUp];
    [element swipeUp];
    
    XCUIElementQuery *collectionViewsQuery = app.collectionViews;
    [collectionViewsQuery.staticTexts[@"Photo Books"] tap];
    [collectionViewsQuery.staticTexts[@"A5 Landscape"] tap];
    [app.navigationBars[@"A5 Landscape Photobook"].buttons[@"Next"] tap];
    [app.navigationBars[@"Move Pages"].buttons[@"Next"] tap];
    [app.navigationBars[@"Review"].buttons[@"Confirm"] tap];
    [app.tables.buttons[@"button apple pay"] tap];
    [app.buttons[@"Pay"] tap];
    
}

@end
