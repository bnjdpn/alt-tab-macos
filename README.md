# AltTab Free

AltTab Free is a free and open-source macOS window switcher.

[benjamindupin/alt-tab-pro-but-free](https://github.com/benjamindupin/alt-tab-pro-but-free) is a fork of [lwouis/alt-tab-macos](https://github.com/lwouis/alt-tab-macos).

This fork keeps the macOS window switcher functionality available without paid tiers, trials, license activation, checkout pages, or proprietary feedback/license services.

This is an independent modified version. It is not affiliated with, endorsed by, or distributed by the upstream AltTab maintainer.

## Changes from upstream

- Pro/license checks are disabled and all former Pro-gated features are available.
- Upgrade, account, checkout, and trial prompts are removed from the visible app flows.
- Feedback opens a prefilled GitHub issue instead of posting to the upstream private API.
- Automatic updates are disabled until this fork publishes its own Sparkle appcast.
- The app uses its own bundle identity: `com.benjamindupin.alt-tab-free`.
- Upstream release services, website deployment, funding links, AppCenter symbols, Sparkle keys, and Developer ID identity are not used by this fork.

## Build

```bash
./ai/build.sh
```

Unsigned source-only verification can be run with:

```bash
xcodebuild -project alt-tab-macos.xcodeproj -scheme Debug -configuration Debug -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-
```

## License

This project is distributed under GPL-3.0. See [LICENCE.md](LICENCE.md) and [NOTICE.md](NOTICE.md).

Binary releases, if published, must provide source code for the exact released build and must be signed/notarized only with this fork maintainer's own credentials.
