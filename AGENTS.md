# Tock Agent Notes

## Repo Layout

- macOS app source lives in `Tock/` with the Xcode project at `Tock.xcodeproj`.
- Marketing site assets live under `assets/` and are served by `index.html`.
- Help page lives at `help/index.html`; 404 page is `404.html`.

## Web Assets

- SCSS source: `assets/scss/site.scss`
- Compiled CSS: `assets/css/site.css`
- Vendor reset: `assets/css/reset.css` (linked before `site.css` in `index.html`)
- Images: place in `assets/img/`
- Layout note: prefer CSS Grid for layout; avoid Flexbox.
- URL paths: use relative paths for local dev; `404.html` uses a `<base>` tag + small script to set `/tock/` on GitHub Pages.

## Docs

- In Markdown, wrap multi-line commands in fenced code blocks with blank lines around them so the MD linter passes.
- Leave a blank line before and after fenced code blocks.

## Release Workflow (Developer ID)

- The canonical release artifact is the signed + notarized DMG built locally (not the GitHub Actions build).
- Xcode: Archive → Distribute App → Direct Distribution to notarize the app.
- DMG packaging: use `scripts/make-dmg.sh` and set `SIGNING_IDENTITY` (required; script fails if missing).
- Notarize + staple the DMG with `notarytool`, then verify Gatekeeper on the installed app.

## macOS Menu Behavior

- Favor standard macOS behaviors and interaction patterns whenever possible. If a proposed change deviates from platform norms, call it out explicitly before implementing.
