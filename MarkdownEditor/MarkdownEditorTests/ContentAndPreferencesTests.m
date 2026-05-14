#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/PreferenceManager.h"

@interface ContentAndPreferencesTests : XCTestCase
@end

@implementation ContentAndPreferencesTests

- (void)setUp {
    [super setUp];
    [PreferenceManager.sharedManager resetToDefaults];
}

- (void)tearDown {
    [PreferenceManager.sharedManager resetToDefaults];
    [super tearDown];
}

- (void)testPreferenceManagerDefaultsAutoReloadEnabled {
    XCTAssertTrue(PreferenceManager.sharedManager.autoReloadEnabled);
}

- (void)testPreferenceManagerStoresAutoReloadEnabled {
    XCTAssertTrue(PreferenceManager.sharedManager.autoReloadEnabled);

    PreferenceManager.sharedManager.autoReloadEnabled = YES;
    XCTAssertTrue(PreferenceManager.sharedManager.autoReloadEnabled);

    PreferenceManager.sharedManager.autoReloadEnabled = NO;
    XCTAssertFalse(PreferenceManager.sharedManager.autoReloadEnabled);
}

- (void)testPreferenceManagerResetToDefaultsClearsAutoReload {
    PreferenceManager.sharedManager.autoReloadEnabled = NO;

    [PreferenceManager.sharedManager resetToDefaults];

    XCTAssertTrue(PreferenceManager.sharedManager.autoReloadEnabled);
}

@end
