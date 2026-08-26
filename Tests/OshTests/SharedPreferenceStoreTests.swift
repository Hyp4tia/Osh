import XCTest

final class SharedPreferenceStoreTests: XCTestCase {

    private var tempDir: URL!
    private var tempFile: URL!
    private var store: SharedPreferenceStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SharedPreferenceStoreTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        tempFile = tempDir.appendingPathComponent("test-preferences.plist")
        store = SharedPreferenceStore(fileURL: tempFile)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Basic read/write

    func testStringRoundTrip() {
        store.set("dark", forKey: "theme")
        store.synchronize()

        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertEqual(reloaded.string(forKey: "theme"), "dark")
    }

    func testDoubleRoundTrip() {
        store.set(18.5, forKey: "fontSize")
        store.synchronize()

        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertEqual(reloaded.double(forKey: "fontSize"), 18.5, accuracy: 0.01)
    }

    func testBoolRoundTrip() {
        store.set(false, forKey: "enableMermaid")
        store.synchronize()

        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertEqual(reloaded.bool(forKey: "enableMermaid"), false)
    }

    func testMissingKeyDefaults() {
        XCTAssertNil(store.string(forKey: "nonexistent"))
        XCTAssertEqual(store.double(forKey: "nonexistent"), 0)
        XCTAssertEqual(store.bool(forKey: "nonexistent"), false)
        XCTAssertNil(store.object(forKey: "nonexistent"))
        XCTAssertNil(store.dictionary(forKey: "nonexistent"))
        XCTAssertNil(store.array(forKey: "nonexistent"))
    }

    func testRemoveObject() {
        store.set("value", forKey: "key")
        store.removeObject(forKey: "key")
        store.synchronize()

        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertNil(reloaded.string(forKey: "key"))
    }

    func testSetNilRemovesKey() {
        store.set("value", forKey: "key")
        store.setNil(forKey: "key")
        store.synchronize()

        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertNil(reloaded.object(forKey: "key"))
    }

    // MARK: - Cross-process simulation

    func testCrossProcessRead() {
        // Simulate main app writing
        store.set("dark", forKey: "theme")
        store.set(20.0, forKey: "fontSize")
        store.set(true, forKey: "enableKatex")
        store.synchronize()

        // Simulate extension reading (new instance, same file, alwaysReload mode)
        let extensionStore = SharedPreferenceStore(fileURL: tempFile, alwaysReload: true)
        XCTAssertEqual(extensionStore.string(forKey: "theme"), "dark")
        XCTAssertEqual(extensionStore.double(forKey: "fontSize"), 20.0, accuracy: 0.01)
        XCTAssertEqual(extensionStore.bool(forKey: "enableKatex"), true)
    }

    func testReloadsWhenFileChangesOnDisk() {
        store.set("light", forKey: "theme")
        store.synchronize()

        // Another process writes to the same file
        let otherWriter = SharedPreferenceStore(fileURL: tempFile)
        otherWriter.set("dark", forKey: "theme")
        otherWriter.synchronize()

        // Extension with alwaysReload always picks up changes
        let reader = SharedPreferenceStore(fileURL: tempFile, alwaysReload: true)
        XCTAssertEqual(reader.string(forKey: "theme"), "dark")
    }

    func testAlwaysReloadPicksUpEveryChange() {
        let reader = SharedPreferenceStore(fileURL: tempFile, alwaysReload: true)

        store.set("v1", forKey: "key")
        store.synchronize()
        XCTAssertEqual(reader.string(forKey: "key"), "v1")

        store.set("v2", forKey: "key")
        store.synchronize()
        XCTAssertEqual(reader.string(forKey: "key"), "v2")
    }

    // MARK: - File doesn't exist yet

    func testWorksWhenFileDoesNotExist() {
        let missingFile = tempDir.appendingPathComponent("does-not-exist.plist")
        let emptyStore = SharedPreferenceStore(fileURL: missingFile)

        XCTAssertNil(emptyStore.string(forKey: "anything"))
        XCTAssertEqual(emptyStore.double(forKey: "anything"), 0)
    }

    func testCreatesFileOnFirstSynchronize() {
        let newFile = tempDir.appendingPathComponent("new-prefs.plist")
        XCTAssertFalse(FileManager.default.fileExists(atPath: newFile.path))

        let newStore = SharedPreferenceStore(fileURL: newFile)
        newStore.set("test", forKey: "key")
        let success = newStore.synchronize()

        XCTAssertTrue(success)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFile.path))
    }

    // MARK: - Synchronize return value

    func testSynchronizeReturnsTrueOnSuccess() {
        store.set("value", forKey: "key")
        XCTAssertTrue(store.synchronize())
    }

    func testSynchronizeReturnsFalseForReadOnlyLocation() {
        // Create a temp directory, write a file, then chmod to read-only
        let readOnlyDir = tempDir.appendingPathComponent("readonly")
        try? FileManager.default.createDirectory(at: readOnlyDir, withIntermediateDirectories: true)
        let readOnlyFile = readOnlyDir.appendingPathComponent("prefs.plist")

        // Write initial file
        let initialStore = SharedPreferenceStore(fileURL: readOnlyFile)
        initialStore.set("initial", forKey: "key")
        initialStore.synchronize()

        // Make directory read-only
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: readOnlyDir.path
        )

        // New store should detect it's not writable
        let readOnlyStore = SharedPreferenceStore(fileURL: readOnlyFile)
        readOnlyStore.set("updated", forKey: "key")
        XCTAssertFalse(readOnlyStore.synchronize())

        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: readOnlyDir.path
        )
    }

    // MARK: - Thread safety

    func testConcurrentReadWriteDoesNotCrash() {
        let iterations = 1000
        let expectation = self.expectation(description: "concurrent access")
        expectation.expectedFulfillmentCount = 2

        DispatchQueue.global().async {
            for i in 0..<iterations {
                self.store.set("value-\(i)", forKey: "key")
                if i % 100 == 0 { self.store.synchronize() }
            }
            expectation.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0..<iterations {
                _ = self.store.string(forKey: "key")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: - Plist validation

    func testSynchronizeWithCorruptedPlistOnDisk() {
        // Write garbage to the plist file
        try? "not a plist".data(using: .utf8)?.write(to: tempFile)

        // Store should still work with its in-memory cache
        let storeWithBadFile = SharedPreferenceStore(fileURL: tempFile)
        storeWithBadFile.set("works", forKey: "key")
        let success = storeWithBadFile.synchronize()

        // Should succeed (overwrites the corrupt file with valid plist)
        XCTAssertTrue(success)

        // Verify the file is now valid
        let reloaded = SharedPreferenceStore(fileURL: tempFile)
        XCTAssertEqual(reloaded.string(forKey: "key"), "works")
    }
}
