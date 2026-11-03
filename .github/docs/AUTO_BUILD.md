# Rembrandt automatic upstream sync and releases

Upstream: https://github.com/thesnarkitecht/rembrandt (`main`).

- **Cadence**: GitHub Actions checks the upstream commit every 10 minutes (scheduled checks may be delayed).
- **Change detection**: compare the official SHA against `.github/sync/upstream-head.sha`. Identical SHA skips compilation and publishing.
- **Mirror**: on change, copy the upstream source snapshot into local `main` with a normal descendant commit; no history force-push. All files except local automation controls follow upstream.
- **Preserved automation**: `.github/workflows/auto-sync-release.yml`, `.github/workflows/build-mirror.yml`, `.github/scripts/sync-upstream.sh`, and this document.
- **Exact-source builds**: the local reusable build workflow is derived from upstream's successful `.github/workflows/build.yml` and explicitly checks out `needs.sync.outputs.mirror_sha`, not the triggering workflow SHA.
- **Targets**: macOS Apple Silicon and Intel DMG; Windows x64 NSIS and MSI; Windows ARM64 NSIS; Linux x64 and ARM64 AppImage, DEB, RPM; and the `rembrandt-server` archive for each OS/architecture.
- **Toolchain**: official Node 22 / `npm ci` / `npm run check`, Rust/Tauri 2 desktop, Cargo server, Rust build caching, OS-specific system prerequisites.
- **Publish**: after all required platforms pass, publish an **unofficial pre-release** `rembrandt-vVERSION-SOURCE_SHA12` with checksums and upstream commit metadata. No releases when the SHA is unchanged.
- **Manual rebuild**: Actions > Rembrandt - auto sync and multi-platform release > Run workflow > enable `force_build`.

The source is not modified in the CI build process, and the original upstream `.github/workflows/release.yml`, `build.yml`, `ci.yml` are kept. The automation-generated binaries are not official upstream releases and are unsigned except for ad-hoc macOS signing. A full six-platform build can take substantial GitHub Actions time, especially when upstream pushes frequently.

Do not maintain custom source edits on the mirrored `main` branch: the next synchronization will replace non-control files. Use a separate feature branch for custom changes. The GitHub Actions `GITHUB_TOKEN` push does not recursively trigger the original upstream workflows.
