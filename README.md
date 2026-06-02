# AltTab Free

AltTab Free is a free and open-source fork of [lwouis/alt-tab-macos](https://github.com/lwouis/alt-tab-macos).

This fork keeps the macOS window switcher functionality available without paid tiers, trials, license activation, checkout pages, or proprietary feedback/license services.

## Changes from upstream

- Pro/license checks are disabled and all former Pro-gated features are available.
- Upgrade, account, checkout, and trial prompts are removed from the visible app flows.
- Feedback opens a prefilled GitHub issue instead of posting to the upstream private API.
- Automatic updates are disabled until this fork publishes its own Sparkle appcast.
- The app uses its own bundle identity: `com.benjamindupin.alt-tab-free`.

## Build

```bash
./ai/build.sh
```

## License

This project is distributed under GPL-3.0, matching upstream. See [LICENCE.md](LICENCE.md).

Original project: [lwouis/alt-tab-macos](https://github.com/lwouis/alt-tab-macos).
