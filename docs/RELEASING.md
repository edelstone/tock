# Releasing

The canonical release artifact is the signed + notarized DMG you build locally.

GitHub Actions only creates the GitHub Release page and runs an unsigned build check when a version tag is pushed. You upload the signed DMG to that release.

## Prerequisites

- Xcode installed.
- `Tock` scheme is shared in Xcode (Xcode → Manage Schemes → Shared).
- GitHub CLI (`gh`) for creating/editing release notes from the terminal.

## Development

Open `Tock.xcodeproj`, select the `Tock` scheme, and run from Xcode.

## Signed & notarized DMG (Developer ID)

Use this flow for the official non–App Store release (v0.1.23+). It produces a signed, notarized, stapled DMG.

1. Ensure app metadata is complete.
   - `Info.plist` includes `CFBundlePackageType` set to `APPL`.
2. Archive and notarize the app in Xcode.
   - Xcode → Target `Tock` → Signing & Capabilities:
     - Team: your paid team
     - Automatically manage signing: off
     - Signing Certificate (Release): Developer ID Application
   - Product → Archive
   - Organizer → Distribute App → Direct Distribution
   - Wait for notarization to succeed, then export `Tock.app`.
3. Verify the exported app passes Gatekeeper.

   ```bash
   spctl -a -vv /path/to/Tock.app
   ```

4. Build a DMG from the notarized app.

   ```bash
   cd /path/to/tock
   rm -rf dist
   mkdir -p dist
   ./scripts/make-dmg.sh "/path/to/Tock.app" "dist/Tock.dmg"
   ```

5. Notarize the DMG with `notarytool`.
   - One-time setup (stores credentials in Keychain):

     ```bash
     xcrun notarytool store-credentials "tock-notary"
     ```

   - Submit and wait (can take a few minutes):

     ```bash
     xcrun notarytool submit "dist/Tock.dmg" --keychain-profile "tock-notary" --wait
     ```

6. Staple and validate the DMG.

   ```bash
   xcrun stapler staple "dist/Tock.dmg"
   xcrun stapler validate "dist/Tock.dmg"
   ```

7. Final smoke check.
   - Mount `dist/Tock.dmg`, drag `Tock.app` to `/Applications`, then:

     ```bash
     spctl -a -vv /Applications/Tock.app
     ```

8. Launch `Tock.app` from `/Applications` and verify core behavior, notifications, settings, and shortcuts.

## Publish a release (GitHub)

1. Commit and push all release changes.
2. Create and push a lightweight tag with the next sequential version number.
   - `git tag v0.1.0`
   - `git push origin v0.1.0`
3. A GitHub Release is created automatically by CI and is named after the tag.
4. Upload the signed DMG you produced locally (CI does not upload artifacts).

   ```bash
   cd /path/to/tock
   gh release upload v0.1.0 dist/Tock.dmg --clobber
   ```

5. Add or update release notes.
   - If you see “release not found”, wait for CI to finish.
   - `gh release edit v0.1.0 --notes $'Highlights:\n- First item\n- Second item'`
6. Download and install the DMG from the GitHub Release.
   - This DMG matches the signed + notarized artifact you uploaded.
   - If macOS blocks launch:  
     `xattr -dr com.apple.quarantine /Applications/Tock.app`

### If CI fails after tagging

1. Delete the bad tag locally and remotely.
   - `git tag -d v0.1.0 || true && git push origin :v0.1.0`
2. Fix the issue.
3. Re-tag and push again.

## Post-release usage

Use the app installed from the GitHub Release in `/Applications`.

To update, download and reinstall the latest DMG from the Releases page.
