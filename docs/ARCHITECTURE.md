# Architecture

## Design overview

```text
+---------------------+
| SwiftUI interface   |  Native top toolbar, settings
+----------+----------+
           |
           v
+---------------------+
| WKWebView           |  Mobile website + persistent website data
+----------+----------+
           |
    +------+-------+
    |              |
    v              v
+----------+   +-------------------+
| JavaScript|   | WKNavigationDelegate|
| DOM filter|   | URL-path checks   |
+-----+----+   +-------------------+
      |
      v
+---------------------+
| MutationObserver    |  Reapply filter to dynamically loaded content
+---------------------+
```

## Lock In Gram

- Entry point: `apps/LockInGram/LockInGram/LockInGramApp.swift`.
- Main view and Instagram browser: `apps/LockInGram/LockInGram/ContentView.swift`.
- Base URL: `https://www.instagram.com/`.
- Filters known `/reel/` and `/reels/` paths, with extra opt-in Explore/suggested-post rules.
- Keeps Reel message previews where possible so ordinary DM media is not unintentionally removed; opening Reel URLs is still restricted.

## Lock In Tube

- Entry point: `apps/LockInTube/LockInTube/LockInTubeApp.swift`.
- Main view and YouTube browser: `apps/LockInTube/LockInTube/ContentView.swift`.
- Base URL: `https://m.youtube.com/`.
- Filters known `/shorts/` paths and Shorts DOM cards, plus known Community-post containers in Home and Subscriptions.
- The optional Home-feed setting hides selected recommendation containers.

## Design choices and trade-offs

1. **Mobile web instead of private APIs:** Avoids undocumented account APIs, but lacks native-app feature parity and can be affected by website changes.
2. **Website navigation remains visible:** Avoids maintaining a duplicate bottom navigation bar, but depends on YouTube/Instagram's own page layout.
3. **Best-effort DOM filtering:** CSS selectors are simple and fast but depend on unstable third-party markup.
4. **Default WebKit website data store:** Retains normal web cookies where supported. It also means accounts may remain signed in on a shared device.
5. **No background processing:** Neither app implements push notifications, background DM polling or usage monitoring.

## Next engineering steps

- Extract filtering logic into maintainable JavaScript assets with fixture-based tests.
- Add testable URL classification helpers, including nested and edge-case URLs.
- Improve failure visibility without collecting private browsing data.
- Test on multiple iOS versions and screen sizes.
- Investigate Safari extension alternatives where platform terms and technical constraints permit.
