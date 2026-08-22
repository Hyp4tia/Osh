# Project Rules

## 1. Development Process
- **TDD (Test-Driven Development)**: Always write a verifiable test case or define a strict acceptance metric BEFORE writing implementation code.
- **Red-Green-Refactor**: Ensure tests fail before fixing them.
- **Commit Early & Often**: Proactively commit code or ask to commit after completing a significant step or task. Always ask to commit code after finishing a work item.

## 2. Ecosystem & Dependencies
- **No Reinventing Wheels**: Prioritize established npm packages or Swift libraries over custom implementations.
- **Dependency Management**: Strictly manage versions in `package.json`.

## 3. Documentation (Doc-First)
- **Centralized Docs**: All design decisions, architectural changes, and rules must be recorded in the `docs/` directory.
- **Traceability**: Code changes should track back to a documented requirement or bug report.

## 4. Code Quality
- **Review**: Self-review code against these rules before submitting.

## 5. Debug Process & Rules
- **Documentation First**: Before diving into code, create a debug tracking document (e.g., `docs/DEBUG_ISSUE_NAME.md`).
- **Log Current State**: Record the initial symptom, current code version, and reproduction steps in the doc.
- **Automated Observation**: Ensure you can automatically retrieve logs and state (Swift `os_log`, JS console logs bridged to Swift). Do not rely on manual user reporting if automation is possible.
- **Iterative Approach**:
    1.  **Hypothesis**: Formulate a hypothesis based on logs/evidence.
    2.  **Instrument**: Add specific logging or test code to validate the hypothesis.
    3.  **Deploy**: Run the build/install process.
    4.  **Verify**: Check the automated logs.
    5.  **Record**: Update the debug doc with findings.
    6.  **Refine**: If not fixed, repeat. If fixed, clean up debug code.
- **Clean Up**: Remove temporary logging and revert debug-specific configuration changes before final submission.
- **One Step at a Time**: Change one variable at a time to isolate the root cause.
