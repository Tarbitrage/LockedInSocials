# Manual test plan

**Status:** These test cases are instructions, not claims that the test has passed. Test both logged-out and logged-in states where sign-in is supported.

## Common setup

- Record Xcode version, macOS version, iPhone model and iOS version in your *private* testing notes.
- Build both apps with a Personal Team; confirm no unrequested entitlements or permissions.
- Install and launch each app, then reload its web page.
- Check light mode, dark mode, portrait and reconnecting after loss of network access.

## Lock In Gram

- [ ] Instagram mobile site loads.
- [ ] Website's bottom navigation appears only once.
- [ ] Reels navigation item is hidden when detectable.
- [ ] A direct `/reel/` link is blocked.
- [ ] Home feed regular photo/carousel posts remain.
- [ ] Direct messages load (where website supports them).
- [ ] Photos shared in DMs display correctly.
- [ ] Ordinary videos shared in DMs play.
- [ ] A shared Reel preview does not hide the whole DM conversation.
- [ ] Stories and profiles work as supported by the website.
- [ ] Hide Explore setting survives relaunch.
- [ ] Suggested-post filter does not hide unrelated posts.

## Lock In Tube

- [ ] YouTube mobile website loads.
- [ ] A standard watch video plays.
- [ ] Search returns normal videos.
- [ ] Shorts bottom-navigation item is hidden when detectable.
- [ ] Shorts card and shelf are hidden when detectable.
- [ ] A direct `/shorts/` link is blocked.
- [ ] Community photo/poll/text post is hidden in Home feed.
- [ ] Community post is hidden in Subscriptions feed.
- [ ] Normal video cards and comments remain.
- [ ] Optional Home-feed hiding can be enabled and disabled.
- [ ] Account-login restrictions are documented if encountered.

## Regression checklist

After changing a CSS selector or URL rule, recheck regular media, website navigation, settings persistence, and normal external links. Never attach usernames, account cookies or screenshots of private messages to public issues.

## Automated checks

Run `python3 scripts/check_repo.py` to validate the shipped source and asset structures. On macOS with Xcode, the CI workflow attempts simulator builds without signing. No automated test in this repository currently verifies live Instagram/YouTube DOM behaviour.
