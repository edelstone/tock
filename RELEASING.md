# Releasing

This guide covers the end-to-end workflows for shipping Tock through supported distribution channels.

## Version, build, and tag rules

### App Store (App Store Connect)

- Version = what users see.
- Build = Apple’s upload counter.
- Build must increase on every upload, even if Version does not.
- Increment Version only when you are publishing a new release. For re-uploads, keep Version the same and increment Build.

### DMG (GitHub)

- Version must change for every public DMG.
- Build is optional and may stay at `1` if Version always changes.

### GitHub tags

- One tag = one exact DMG
- Never replace a DMG under an existing tag.
- If you rebuild, make a new tag (new Version, or same Version with a build/suffix).

## Prerequisites

- Xcode installed.
- `Tock` scheme is shared in Xcode (Xcode → Manage Schemes → Shared).
- GitHub CLI (`gh`) for creating/editing release notes from the terminal.

## Development

Open `Tock.xcodeproj`, select the `Tock` scheme, and run from Xcode.

## Release paths

This repo supports two release paths: the Mac App Store flow and the signed + notarized DMG flow for GitHub Releases.

### Mac App Store

Use this flow for the Mac App Store build (App Store Connect).

1. Bump the app version/build in Xcode.
   - Target `Tock` → General → Version (MARKETING_VERSION) and Build (CURRENT_PROJECT_VERSION).
   - Bump Build to a new integer _every upload_ (App Store Connect rejects reused build numbers).

2. Archive and upload from Xcode.
   - Target `Tock` → Signing & Capabilities:
     - Automatically manage signing: On
     - Team: your paid team
     - Signing to run locally: Development
   - Product → Archive
   - Archive Organizer → Distribute App → App Store Connect → Upload

3. Complete the release in App Store Connect (the Xcode upload only delivers the build).
   - App Store Connect → My Apps → Tock.
   - Click the “+” next to Versions and pick the new version number.
   - On the new version page, set the build by clicking “Select a build” and choosing the uploaded archive.
   - Fill any required metadata (What’s New, age rating, etc.) and resolve validation errors.
   - Click “Submit for Review”.
   - After approval, click “Release” or enable “Automatically release this version” before submission.

### Signed & notarized DMG

Use this flow for the official non–App Store release. It produces a signed, notarized, and stapled DMG.

1. Bump the app version/build in Xcode.
   - Target `Tock` → General → Version (MARKETING_VERSION) and Build (CURRENT_PROJECT_VERSION).
   - These values control the app’s reported version everywhere (Finder, About screen, crash logs).

2. Archive and notarize the app in Xcode.
   - Target `Tock` → Signing & Capabilities:
     - Build configuration: Release (Archive uses Release by default)
     - Automatically manage signing: off
     - Provisioning profile: none
     - Team: your paid team
     - Signing Certificate: Developer ID Application
   - Product → Archive
   - Archive Organizer → Distribute App → Direct Distribution
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

5. Notarize the DMG with `notarytool`.
   - One-time setup (per machine, just run once):

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

#### Publish a release (GitHub)

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
