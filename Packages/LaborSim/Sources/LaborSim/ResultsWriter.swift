import Foundation

/// Per-scenario JSON emission, off by default.
///
/// The harness runs inside `xcodebuild test`, where anything written to an
/// unpredictable working directory is litter. So the writer is inert unless
/// `LABOR_QA_OUT` names a directory — the aggregate report generator sets it, the
/// edit-test loop does not, and neither has to know about the other.
public enum ResultsWriter {
    public static let environmentKey = "LABOR_QA_OUT"

    /// The fallback handover, and why it has to exist.
    ///
    /// These tests run inside the iOS simulator, and the simulator hands the test
    /// process a fixed environment of its own: nothing the caller exports reaches it,
    /// and neither `TEST_RUNNER_`- nor `SIMCTL_CHILD_`-prefixed variables are
    /// forwarded for a Swift-package test bundle (both were tried; the test process
    /// sees `SIMULATOR_*`, `DYLD_*` and little else). What the simulator *can* do is
    /// read and write ordinary host paths. So when the environment is silent, the
    /// destination is read from a one-line file in the host's home directory —
    /// `SIMULATOR_HOST_HOME` is one of the variables the simulator does provide.
    ///
    /// The caller writes it and removes it:
    ///
    ///     echo "$OUT" > ~/.hushlight-labor-qa-out
    ///     ./scripts/test.sh LaborSim
    ///     rm ~/.hushlight-labor-qa-out
    ///
    /// It is opt-in in exactly the way the environment variable was meant to be: no
    /// file, no output, and the edit-test loop never writes anything.
    public static let pointerFileName = ".hushlight-labor-qa-out"

    /// The run directory, or nil when the harness is running as ordinary unit tests.
    public static var outputRoot: URL? {
        let environment = ProcessInfo.processInfo.environment
        if let path = environment[environmentKey], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        guard let home = environment["SIMULATOR_HOST_HOME"] ?? environment["HOME"] else {
            return nil
        }
        let pointer = URL(fileURLWithPath: home).appendingPathComponent(pointerFileName)
        guard let data = try? Data(contentsOf: pointer),
              let path = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty
        else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    /// Nil when the harness is running as ordinary unit tests.
    public static var outputDirectory: URL? {
        outputRoot?.appendingPathComponent("results")
    }

    /// One file per scenario per leg: `<dir>/results/<id>.<leg>.json`.
    ///
    /// Returns whether anything was written, so a caller that *wants* output can
    /// assert on it. Failures are swallowed rather than thrown: a full disk should
    /// cost the report, never the verdict of the test run that produced it.
    @discardableResult
    public static func write<T: Encodable>(_ payload: T, scenario id: String, leg: String) -> Bool {
        guard let directory = outputDirectory else { return false }
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )
            let data = try CanonicalJSON.data(payload, pretty: true)
            try data.write(to: directory.appendingPathComponent("\(id).\(leg).json"))
            return true
        } catch {
            return false
        }
    }
}
