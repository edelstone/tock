# Releasing

This repo includes a GitHub Actions workflow that builds an unsigned DMG on tag pushes and uploads it to a GitHub Release. (Unsigned means macOS may warn on first launch.)

Prereqs:

- Xcode installed (for local builds).
- The `Tock` scheme is shared in Xcode (Manage Schemes → Shared). This is a one-time setup; skip if it is already shared.
- GitHub CLI (`gh`) installed if you want to publish release notes from the terminal.

Before tagging, make sure all release changes are committed and pushed, then:

1. Tag a release: `git tag v0.1.0`
1. Push the tag: `git push origin v0.1.0`
1. Optional: add GitHub Release notes with the CLI (supports bullet lists):
   - `gh release create v0.1.0 --notes $'Highlights:\n- First item\n- Second item'`
1. Optional: download the GitHub Release DMG and smoke test it (CI artifact that users get).

## Personal dev workflow

1. Development: open `Tock.xcodeproj`, select the `Tock` scheme, and run from Xcode.
2. Pre-release: rebuild the unsigned DMG locally, then install and test that build.
   - Build DMG:

     ```bash
     cd /Users/Michael/Sites/tock
     xcodebuild -scheme Tock -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO
     ./scripts/make-dmg.sh "build/Build/Products/Release/Tock.app" "dist/Tock.dmg"
     ```

   - Install from: `dist/Tock.dmg` (drag to `/Applications`).
3. Release: once the DMG build passes, follow the release steps above (commit/push, tag, push tag).
4. Daily use: run the installed app from `/Applications`; update it by reinstalling the latest `dist/Tock.dmg` when needed.
