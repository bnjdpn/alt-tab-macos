import XCTest

final class LicenseManagerTests: XCTestCase {
    var clock: MockClock!
    var keychain: MockKeychain!
    var api: MockLicenseAPI!
    var defaults: UserDefaults!
    var suiteName: String!
    var manager: LicenseManager!

    override func setUp() {
        super.setUp()
        suiteName = "test-license-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        clock = MockClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        keychain = MockKeychain()
        api = MockLicenseAPI()
        manager = LicenseManager(clock: clock, keychain: keychain, api: api, defaults: defaults)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testInitializeIsAlwaysFreeUnlocked() {
        manager.initialize()
        XCTAssertEqual(manager.state, .pro)
        XCTAssertTrue(manager.isProAvailable)
        XCTAssertFalse(manager.isProLocked)
        XCTAssertTrue(manager.isLifetimeVariant)
        XCTAssertNil(manager.trialStartDate)
        XCTAssertEqual(manager.daysSinceTrialStart, 0)
    }

    func testComputeStateIgnoresStoredLicenseData() {
        keychain.setValue("OLD-KEY", account: LicenseManager.keychainKeyAccount)
        defaults.set(false, forKey: "lastValidationResult")
        defaults.set(clock.now.addingTimeInterval(-365 * 86400).timeIntervalSince1970, forKey: "trialStartDate")
        XCTAssertEqual(manager.computeState(), .pro)
    }

    func testActivateDoesNotCallApiOrWriteKeychain() {
        let exp = expectation(description: "activate")
        manager.activate("ANY-KEY") { result in
            if case .failure(let error) = result { XCTFail("expected success, got \(error)") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(manager.state, .pro)
        XCTAssertEqual(api.activateCalls.count, 0)
        XCTAssertNil(keychain.value(account: LicenseManager.keychainKeyAccount))
    }

    func testDeactivateKeepsFreeUnlockedState() {
        let exp = expectation(description: "deactivate")
        manager.deactivate { result in
            if case .failure(let error) = result { XCTFail("expected success, got \(error)") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(manager.state, .pro)
        XCTAssertEqual(api.deactivateCalls.count, 0)
    }

    func testRemoteRevalidationIsDisabled() {
        manager.scheduleAsyncRevalidationIfNeeded()
        manager.revalidateWithServer()
        XCTAssertEqual(api.validateCalls.count, 0)
        XCTAssertEqual(manager.state, .pro)
    }

    func testOnBeforeProUnlockStillFiresForCompatibility() {
        var hookFired = false
        manager.onBeforeProUnlock = { hookFired = true }
        let exp = expectation(description: "activate")
        manager.activate("ANY-KEY") { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(hookFired)
        XCTAssertEqual(manager.state, .pro)
    }

    #if DEBUG
    func testDebugMocksKeepUnlockedState() {
        manager.mockTrialUser()
        XCTAssertEqual(manager.state, .pro)
        manager.mockTrialExpired()
        XCTAssertEqual(manager.state, .pro)
        manager.mockTrialDay(14)
        XCTAssertEqual(manager.state, .pro)
        manager.mockProUser()
        XCTAssertEqual(manager.state, .pro)
    }
    #endif
}

final class MockClock: Clock {
    var now: Date
    init(now: Date) { self.now = now }
    func advance(by interval: TimeInterval) { now = now.addingTimeInterval(interval) }
    func advance(days: Int) { now = now.addingTimeInterval(Double(days) * 86400) }
}

final class MockKeychain: Keychain {
    private var store: [String: String] = [:]
    var setValueStatus: (String) -> OSStatus = { _ in errSecSuccess }
    var removeStatus: (String) -> OSStatus = { _ in errSecSuccess }

    func value(account: String) -> String? { store[account] }

    @discardableResult
    func setValue(_ value: String, account: String) -> OSStatus {
        let status = setValueStatus(account)
        if status == errSecSuccess { store[account] = value }
        return status
    }

    @discardableResult
    func remove(account: String) -> OSStatus {
        let status = removeStatus(account)
        if status == errSecSuccess { store.removeValue(forKey: account) }
        return status
    }
}

final class MockLicenseAPI: LicenseAPI {
    var activateCalls: [String] = []
    var validateCalls: [(String, String)] = []
    var deactivateCalls: [(String, String)] = []

    func activate(_ licenseKey: String, completion: @escaping (Result<ActivateResult, Error>) -> Void) {
        activateCalls.append(licenseKey)
        DispatchQueue.main.async { completion(.failure(LicenseAPIError.noData)) }
    }

    func validate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<ValidateResult, Error>) -> Void) {
        validateCalls.append((licenseKey, instanceId))
        DispatchQueue.main.async { completion(.failure(LicenseAPIError.noData)) }
    }

    func deactivate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deactivateCalls.append((licenseKey, instanceId))
        DispatchQueue.main.async { completion(.failure(LicenseAPIError.noData)) }
    }
}
