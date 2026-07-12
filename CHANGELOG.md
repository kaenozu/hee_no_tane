# Changelog

## 1.0.0

Initial distribution-ready release candidate.

### Added

- Three-step first-run onboarding
- Daily quiz, explanation, and knowledge-card reward flow
- Collection, card details, streak, and browse statistics
- Shareable 1080×1350 PNG card images
- In-app privacy policy, support guidance, and open-source licenses
- Recoverable startup and save-data load errors
- Signed Android App Bundle and Web artifact workflow
- Android, iOS, and Web build checks in CI

### Fixed

- Prevented stale save snapshots and concurrent writes from losing progress
- Made answer retries idempotent
- Prevented duplicate onboarding and share actions
- Corrected Android, iOS, and Web product names to「へぇのタネ」
- Restored CI push checks for the repository's `master` branch
