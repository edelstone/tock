# Releasing

Build the signed + notarized DMG locally, then upload it to the GitHub Release.

## Prerequisites

- Xcode installed.
- `Tock` scheme is shared in Xcode (Xcode → Manage Schemes → Shared).
- GitHub CLI (`gh`) for creating/editing release notes from the terminal.

## Development

Open `Tock.xcodeproj`, select the `Tock` scheme, and run from Xcode.

## Signed & notarized DMG (Developer ID)

Use this flow for the official non–App Store release. It produces a signed, notarized, and stapled DMG.

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
   SIGNING_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
     ./scripts/make-dmg.sh "/path/to/Tock.app" "dist/Tock.dmg"
   ```

   - `SIGNING_IDENTITY` is required; the script will fail if it is missing.

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
3. After tag is pushed, GitHub Actions creates a GitHub Release named after the tag.
4. Upload the signed DMG you produced locally (GitHub Actions does not upload artifacts).

   ```bash
   cd /path/to/tock
   gh release upload v0.1.0 dist/Tock.dmg --clobber
   ```

   - If you see “release not found”, wait for GitHub Actions to finish and retry commands.
5. Add or update release notes.
   - `gh release edit v0.1.0 --notes $'Highlights:\n- First item\n- Second item'`
6. Download and install the DMG from the GitHub Release. This DMG will match the signed + notarized artifact you uploaded.

### If GitHub Actions fails after tagging

1. Delete the bad tag locally and remotely.
   - `git tag -d v0.1.0 || true && git push origin :v0.1.0`
2. Fix the issue.
3. Re-tag and push again.
