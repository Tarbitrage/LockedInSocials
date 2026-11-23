# Lock In iOS

**Two experimental SwiftUI apps designed to reduce distracting content on Instagram and YouTube without rebuilding their interfaces.**

<p>
  <img src="apps/LockInGram/LockInGram/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="Lock In Gram icon" width="108" />
  &nbsp;&nbsp;&nbsp;
  <img src="apps/LockInTube/LockInTube/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="Lock In Tube icon" width="108" />
</p>

> [!IMPORTANT]
> **Unofficial prototypes.** Not affiliated with, approved by, or endorsed by Meta, Instagram, Google, or YouTube. These apps are website wrappers, not official API clients. They may stop working if the services change. Public/commercial distribution may require additional permissions.

## What they do

| | Lock In Gram | Lock In Tube |
| --- | --- | --- |
| Website | Instagram mobile web | YouTube mobile web |
| Content filter | Hides detectable Reels and blocks Reel URLs | Hides detectable Shorts and blocks Shorts URLs |
| Other filters | Optional Explore and suggested-post hiding | Community posts in feeds; optional Home recommendation hiding |
| Navigation | Original website navigation | Original website navigation |
| Media | Web-supported DM photos and videos | Regular web video playback |
| Main limitation | Website features differ from native Instagram; no native DM push | Google sign-in can be blocked in embedded browsers |

The filters operate on **currently known page structures**. They are not guaranteed to catch every item or prevent every in-site navigation path. Normal photos/videos in Instagram DMs are intended to remain accessible, but not all types of chat media are verified.

## Getting started

**Prerequisites:** a Mac running a suitable version of Xcode, an iPhone (or iOS simulator), and your own Apple Account for device signing.

1. Download or clone this repository.
2. Open **`LockIn.xcworkspace`** in Xcode. Both apps appear as separate projects.
3. Choose the `LockInGram` or `LockInTube` scheme.
4. Select the app target, enable **Automatically manage signing**, and choose your own **Personal Team**.
5. Replace the example bundle ID (`org.example.*`) with a unique one that you control.
6. Select your iPhone and press **Cmd + R**.

For step-by-step instructions, see **[Installation Guide](docs/INSTALLATION.md)**. No reconstruction or copy/paste of Swift files is needed.

## Repository layout

```text
lock-in-ios/
├── LockIn.xcworkspace/       # Open this to work on both apps
├── apps/
│   ├── LockInGram/
│   │   ├── LockInGram.xcodeproj/
│   │   └── LockInGram/       # SwiftUI code and asset catalog
│   └── LockInTube/
│       ├── LockInTube.xcodeproj/
│       └── LockInTube/       # SwiftUI code and asset catalog
├── docs/                    # Installation, architecture, privacy and testing
├── scripts/                 # Repository validation checks
├── .github/workflows/       # iOS simulator build workflow
├── .gitignore
└── LICENSE
```

## Technical design

- **SwiftUI** provides a small native toolbar and filter settings.
- **WKWebView** loads the official websites using WebKit's default persistent website data store.
- **JavaScript** hides selected DOM elements and intercepts recognizable Reels/Shorts URLs.
- **MutationObserver** reapplies filtering after dynamic content loads.
- **WKNavigationDelegate** rejects recognized direct Reel/Shorts navigation.

The app does not use a custom server, analytics SDK, password-collection endpoint, or third-party tracking library. See [Architecture](docs/ARCHITECTURE.md) and [Privacy & security](docs/PRIVACY_AND_SECURITY.md) for important qualifications.

## Development and testing status

- Lock In Gram was reported functional in personal iPhone testing; some Reel viewer transitions and web features remain imperfect.
- Lock In Tube's current Shorts and Community-post filters **have not been independently device-validated** as part of this repository preparation.
- Repository assets, structural metadata and source syntax are checked with `python3 scripts/check_repo.py`.
- A GitHub Actions workflow is included to attempt **unsigned iOS simulator builds**. A successful build is not proof that filtering works on the live websites.
- These Xcode projects were assembled outside a Mac environment and **have not yet been opened or compiled with Apple's Xcode tools**. If the first build exposes a project-setting issue, please report it without private account details.

Use the [manual test checklist](docs/TESTING.md) before treating the apps as reliable.

## Known restrictions

Apple and third-party platform rules may restrict distribution. In particular, the Google account login flow may reject embedded browsers; the code does not attempt to bypass that restriction. App icons and names are unofficial and do not establish trademark rights. Review [Limitations](docs/LIMITATIONS.md) before sharing a build.

## Contributing

Bug reports and focused improvements are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md) first. Do not post usernames, private messages, passwords, session cookies, device IDs, or Xcode signing credentials in issues.

## License

MIT License for the original code and included icon assets; see [LICENSE](LICENSE). It does **not** grant rights to third-party trademarks, websites, or user content.
