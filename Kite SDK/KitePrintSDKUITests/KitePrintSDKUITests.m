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
    
    XCUIElementQuery *collectionViewsQuery = app.collectionViews;
    XCUIElement *photobookElement = collectionViewsQuery.staticTexts[@"Photo Books"];
    
    while (![photobookElement exists]){
        [element swipeUp];
    }
    
    [photobookElement tap];
    [collectionViewsQuery.staticTexts[@"A5 Landscape"] tap];
    [app.navigationBars[@"A5 Landscape Photobook"].buttons[@"Next"] tap];
    [app.navigationBars[@"Move Pages"].buttons[@"Next"] tap];
    [app.navigationBars[@"Review"].buttons[@"Confirm"] tap];
    [app.tables.buttons[@"button apple pay"] tap];
    [app.buttons[@"Pay"] tap];
    
}

//- (void)testCaseCameraRollCredidCardCheckout{
//    XCUIApplication *app = [[XCUIApplication alloc] init];
//    [app.buttons[@"Print Photos at Remote URLs"] tap];
//    [app.alerts[@"Remote URLS"].collectionViews.buttons[@"OK"] tap];
//    
//    XCUIElementQuery *collectionViewsQuery = app.collectionViews;
//    XCUIElement *element = collectionViewsQuery.staticTexts[@"Phone Cases"];
//    
//    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
//    [self expectationForPredicate:exists evaluatedWithObject:element handler:nil];
//    [self waitForExpectationsWithTimeout:50 handler:nil];
//    
//    [element tap];
//    
//    [collectionViewsQuery.staticTexts[@"iPhone 6+"] tap];
//    
//    XCUIElement *detailsStaticText = app.staticTexts[@"Details"];
//    [detailsStaticText tap];
//    [detailsStaticText tap];
//    [app.navigationBars[@"iPhone 6+"].buttons[@"Next"] tap];
//    [collectionViewsQuery.staticTexts[@"+"] tap];
//    [app.sheets.collectionViews.buttons[@"Camera Roll"] tap];
//    
//    XCUIElementQuery *tablesQuery = app.tables;
//    [tablesQuery.cells[@"Camera Roll,1 Photos"] tap];
//    [collectionViewsQuery.images[@"Photo, Landscape, September 10, 2:28 PM"] tap];
//    [app.navigationBars[@"1 Photo Selected"].buttons[@"Done"] tap];
//    [app.navigationBars[@"Reposition the Photo"].buttons[@"Next"] tap];
//    [tablesQuery.buttons[@"More payment options"] tap];
//    
//    
//    XCUIApplication *app2 = [[XCUIApplication alloc] init];
//    XCUIElementQuery *tablesQuery2 = app2.tables;
//    
//    [tablesQuery2.staticTexts[@"Choose Delivery Address"] tap];
//    [tablesQuery2.staticTexts[@"Enter Address Manually"] tap];
//    [tablesQuery2.textFields[@"First Name"] tap];
//    [[[[tablesQuery2.cells containingType:XCUIElementTypeTextField identifier:@"First Name"] childrenMatchingType:XCUIElementTypeTextField] elementBoundByIndex:0] typeText:@"Test"];
//    [tablesQuery2.textFields[@"Last Name"] tap];
//    [[[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField] elementBoundByIndex:1] typeText:@"Test"];
//    [tablesQuery2.textFields[@"Line 1"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"Test"];
//    [tablesQuery2.textFields[@"Line 2"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:2] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"Test"];
//    [tablesQuery2.textFields[@"City"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:3] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"Test"];
//    [tablesQuery2.textFields[@"State"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:4] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"Test"];
//    [tablesQuery2.textFields[@"ZIP Code"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:5] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"Test"];
//    [app2.navigationBars[@"Add Address"].buttons[@"Add"] tap];
//    [tablesQuery2.staticTexts[@"Test, Test, Test, Test, Test, United States"] tap];
//    
//    XCUIElement *textField = [[tablesQuery2.cells containingType:XCUIElementTypeStaticText identifier:@"Email"] childrenMatchingType:XCUIElementTypeTextField].element;
//    [textField tap];
//    [textField typeText:@"test@test.com"];
//    
//    XCUIElement *textField2 = [[tablesQuery2.cells containingType:XCUIElementTypeStaticText identifier:@"Phone"] childrenMatchingType:XCUIElementTypeTextField].element;
//    [textField2 tap];
//    [textField2 typeText:@""];
//    [textField2 typeText:@"123456789"];
//    [app2.navigationBars[@"Shipping"].buttons[@"Next"] tap];
//    [tablesQuery2.buttons[@"Credit Card"] tap];
//    [app2.sheets.collectionViews.buttons[@"Pay with new card"] tap];
//    [tablesQuery2.textFields[@"Card Number"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"4242424242424242"];
//    [tablesQuery2.textFields[@"MM/YY"] tap];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"1220"];
//    [[[[tablesQuery2 childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:2] childrenMatchingType:XCUIElementTypeTextField].element typeText:@"111"];
//    [tablesQuery2.buttons[@"Pay"] tap];
//    [[[[app2.navigationBars[@"Receipt"] childrenMatchingType:XCUIElementTypeButton] matchingIdentifier:@"Back"] elementBoundByIndex:0] tap];
//    
//    
//}

@end
