/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url1 = "www.mozilla.org"
let url2 = "www.facebook.com"

let url1Label = "Internet for people, not profit — Mozilla"
let url2Label = "Facebook - Log In or Sign Up"

class PrivateBrowsingTest: BaseTestCase {
    func testPrivateTabDoesNotTrackHistory() {
        navigator.openURL(url1, waitForLoading: true)
        navigator.goto(BrowserTabMenu)
        // Go to History screen
        waitforExistence(app.tables.cells["History"])
        app.tables.cells["History"].tap()
        navigator.nowAt(BrowserTab)
        waitforExistence(app.tables["History List"])

        XCTAssertTrue(app.tables["History List"].staticTexts[url1Label].exists)
        // History without counting Recently Closed and Synced devices
        let history = app.tables["History List"].cells.count - 2

        XCTAssertEqual(history, 1, "History entries in regular browsing do not match")

        // Go to Private browsing to open a website and check if it appears on History
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")


        navigator.openURL(url2, waitForLoading: true)
        waitForValueContains(app.textFields["url"], value: "facebook")
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells["History"])
        app.tables.cells["History"].tap()
        waitforExistence(app.tables["History List"])
        XCTAssertTrue(app.tables["History List"].staticTexts[url1Label].exists)
        XCTAssertFalse(app.tables["History List"].staticTexts[url2Label].exists)

        // Open one tab in private browsing and check the total number of tabs
        let privateHistory = app.tables["History List"].cells.count - 2
        XCTAssertEqual(privateHistory, 1, "History entries in private browsing do not match")
    }

    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        // Open two tabs in normal browsing and check the number of tabs open
        navigator.openNewURL(urlString: url1)
        waitUntilPageLoad()
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[url1Label])
        let numTabs = app.collectionViews.cells.count
        XCTAssertEqual(numTabs, 2, "The number of regular tabs is not correct")

        // Open one tab in private browsing and check the total number of tabs
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")

        navigator.goto(URLBarOpen)
        waitUntilPageLoad()
        navigator.openURL(url2, waitForLoading: true)
        waitForValueContains(app.textFields["url"], value: "facebook")
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[url2Label])
        let numPrivTabs = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of private tabs is not correct")

        // Go back to regular mode and check the total number of tabs
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertFalse(navigator.userState.isPrivate, "User is not private")

        waitforExistence(app.collectionViews.cells[url1Label])
        waitforNoExistence(app.collectionViews.cells[url2Label])
        let numRegularTabs = app.collectionViews.cells.count
        XCTAssertEqual(numRegularTabs, 2, "The number of regular tabs is not correct")
    }

    func testClosePrivateTabsOptionClosesPrivateTabs() {
        // Check that Close Private Tabs when closing the Private Browsing Button is off by default
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables["AppSettingsTableViewController.tableView"]

        while settingsTableView.staticTexts["Close Private Tabs"].exists == false {
            settingsTableView.swipeUp()
        }

        let closePrivateTabsSwitch = settingsTableView.switches["Close Private Tabs, When Leaving Private Browsing"]

        XCTAssertFalse(closePrivateTabsSwitch.isSelected)

        //  Open a Private tab
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")
        navigator.openURL(url1, waitForLoading: true)

        // Go back to regular browser
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertFalse(navigator.userState.isPrivate, "User is private")

        // Go back to private browsing and check that the tab has not been closed
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")

        waitforExistence(app.collectionViews.cells[url1Label])
        let numPrivTabs = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of tabs is not correct, the private tab should not have been closed")

        // Now the enable the Close Private Tabs when closing the Private Browsing Button
        app.collectionViews.cells[url1Label].tap()
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        closePrivateTabsSwitch.tap()
        navigator.goto(BrowserTab)

        // Go back to regular browsing and check that the private tab has been closed and that the initial Private Browsing message appears when going back to Private Browsing
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertFalse(navigator.userState.isPrivate, "User is private")

        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")

        waitforNoExistence(app.collectionViews.cells[url1Label])
        let numPrivTabsAfterClosing = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsAfterClosing, 0, "The number of tabs is not correct, the private tab should have been closed")
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
    }

    func testPrivateBrowserPanelView() {
        // If no private tabs are open, there should be a initial screen with label Private Browsing
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")

        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
        let numPrivTabsFirstTime = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsFirstTime, 0, "The number of tabs is not correct, there should not be any private tab yet")

        // If a private tab is open Private Browsing screen is not shown anymore
        navigator.goto(BrowserTab)

        //Wait until the page loads and go to regular browser
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertFalse(navigator.userState.isPrivate, "User is private")

        // Go back to private browsing
        navigator.goto(TabTray)
        navigator.performAction(Action.TogglePrivateMode )
        XCTAssertTrue(navigator.userState.isPrivate, "User is private")

        waitforNoExistence(app.staticTexts["Private Browsing"])
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is shown")
        let numPrivTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsOpen, 1, "The number of tabs is not correct, there should be one private tab")
    }
}
