//
//  KitePrintSDKUITests.m
//  KitePrintSDKUITests
//
//  Created by Konstadinos Karayannis on 9/2/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface KitePrintSDKUITests : XCTestCase

@end

@implementation KitePrintSDKUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCaseCheckout{
//    
//    XCUIApplication *app = [[XCUIApplication alloc] init];
//    [app.buttons[@"Print Photos at Remote URLs"] tap];
//    [app.alerts[@"Remote URLS"].collectionViews.buttons[@"OK"] tap];
//    
//    XCUIElementQuery *cellsQuery = app.collectionViews.cells;
//    
//    XCUIElement *element = [[cellsQuery.otherElements containingType:XCUIElementTypeStaticText identifier:@"Tough Phone Cases"] childrenMatchingType:XCUIElementTypeButton].element;
//    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
//    
//    [self expectationForPredicate:exists evaluatedWithObject:element handler:nil];
//    [self waitForExpectationsWithTimeout:50 handler:nil];
//    
//    [element tap];
//    [[[cellsQuery.otherElements containingType:XCUIElementTypeStaticText identifier:@"iPhone 6+"] childrenMatchingType:XCUIElementTypeButton].element tap];
//    [app.navigationBars[@"iPhone 6+ Tough"].buttons[@"Next"] tap];
//    [app.navigationBars[@"Reposition the Photo"].buttons[@"Next"] tap];
//    
//    XCUIElementQuery *tablesQuery = app.tables;
//    [tablesQuery.staticTexts[@"Choose Delivery Address"] tap];
//    [tablesQuery.staticTexts[@"Line1, Line2, London, London, NW3 6HN, United Kingdom"] tap];
//    [app.navigationBars[@"Shipping"].buttons[@"Next"] tap];
//    [tablesQuery.buttons[@"button apple pay"] tap];
//    [app.buttons[@"Pay"] tap];
    
}

@end
