# Releasing

This repo includes a GitHub Actions workflow that builds an unsigned DMG on tag pushes and uploads it to a GitHub Release.

Ensure the `Tock` scheme is shared in Xcode (Manage Schemes → Shared) so CI can build it.

1. Tag a release: `git tag v0.1.0`
1. Push the tag: `git push origin v0.1.0`

## Personal dev workflow

- Daily use: install the latest DMG in `/Applications`.
- Development: run from Xcode.
- Pre-release: build the DMG locally, install it, and test the install flow.
