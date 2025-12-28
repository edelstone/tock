# Releasing

This repo uses GitHub Actions to build and publish an unsigned DMG on tag pushes.

## Prereqs

- Xcode installed (for local builds).
- The `Tock` scheme is shared in Xcode (Manage Schemes → Shared). One-time setup.
- Optional: GitHub CLI (`gh`) installed, if you want to edit release notes from the terminal.

## Development

Open `Tock.xcodeproj`, select the `Tock` scheme, and run from Xcode.

## Pre-release (local)

Build and test the app locally before tagging a release (optional but recommended to catch obvious issues before CI).

1. Build the unsigned DMG.

     ```bash
     cd /path/to/tock
     rm -rf build dist
     mkdir -p dist
     xcodebuild -scheme Tock -configuration Release -destination 'generic/platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
     ./scripts/make-dmg.sh "build/Build/Products/Release/Tock.app" "dist/Tock.dmg"
     ```

2. Install the DMG: open `dist/Tock.dmg` and drag `Tock.app` to `/Applications`.
3. Test the DMG: launch the app and verify core behavior, notifications, and shortcuts.

## Publish a release (CI)

1. Commit and push all new release changes to GitHub.
2. Create an annotated release tag and add release notes in the editor:  
   `git tag -a v0.1.0` (be sure to update the version)
3. Push the tag:  
   `git push origin v0.1.0`
4. Optional: edit the GitHub release notes later with `gh release edit` if needed, for example:  
   `gh release edit v0.1.0 --notes $'Highlights:\n- First item\n- Second item'`
5. Download and install the GitHub Release DMG and verify it launches successfully (this is the exact CI artifact users get).
   - If macOS blocks launch (Gatekeeper), remove quarantine for Tock only:  
     `xattr -dr com.apple.quarantine /Applications/Tock.app`

## Daily use

Use the GitHub Release installed in `/Applications`. To update, download and reinstall the latest DMG from the GitHub Releases page.
