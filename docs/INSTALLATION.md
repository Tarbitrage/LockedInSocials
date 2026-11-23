# Installation guide

This repository includes complete Xcode projects for two **separate apps**. You do not need to create new projects or paste the code into Xcode's templates.

## 1. Install Xcode

1. Install Xcode from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835), if its current version supports your Mac.
2. If the App Store version is incompatible, download a suitable release from [Apple Developer Downloads](https://developer.apple.com/download/all/). Check Apple's Xcode release requirements against both the Mac's macOS version and the iPhone's iOS version.
3. Open Xcode, accept the licence, and install the **iOS platform components** if asked. An iOS simulator runtime is optional when testing only on a physical iPhone.
4. In **Xcode > Settings > Accounts**, sign in with **your own** Apple Account.

A paid membership is not required for direct personal development testing. Free Personal Team provisioning typically expires after seven days, so installations must be re-signed periodically.

## 2. Open the apps

1. Download the repository as a ZIP and extract it, or clone it with Git.
2. Double-click **`LockIn.xcworkspace`**. The workspace includes both app projects.
3. In Xcode's scheme selector choose **LockInGram** or **LockInTube**.
4. Choose the corresponding blue project and the matching **TARGET**.
5. Open **Signing & Capabilities** and enable **Automatically manage signing**.
6. Select **your Personal Team** and replace the placeholder bundle identifier:
   - `org.example.LockInGram` -> a unique ID, e.g. `com.youridentifier.LockInGram`
   - `org.example.LockInTube` -> a different unique ID, e.g. `com.youridentifier.LockInTube`

The placeholder IDs contain no identifying information. Never copy somebody else's team or certificates into your project.

## 3. Install on an iPhone

1. Connect an unlocked iPhone to the Mac using a **data-capable** cable and tap **Trust** if prompted.
2. In Xcode choose **Window > Devices and Simulators** and confirm the device appears.
3. On the iPhone, enable **Settings > Privacy & Security > Developer Mode** when requested, then restart and confirm.
4. Select the **physical iPhone** in Xcode's run-destination selector. A named iPhone simulator is not the same as your phone.
5. Press **Cmd + B** to build. If it succeeds, press **Cmd + R** to install and launch.
6. Repeat using the other app scheme.

If the free developer profile expires, connect the same device and use **Cmd + R** again. Updates with the same bundle ID and signing team generally preserve WebKit data, but a login may occasionally need to be repeated.

## 4. Important checks after installation

- On **Lock In Gram**, verify home navigation, Reels blocking, DMs, photos, videos, and stories.
- On **Lock In Tube**, verify normal videos, Shorts hiding, Community-post hiding, and optional feed restrictions.
- Google may block account login from embedded WebViews. Don't attempt to circumvent Google's authentication protections.
- If the app behaves unexpectedly, use its Reload button. Website DOM changes can invalidate filtering.

See the complete [Test Plan](TESTING.md).

## Troubleshooting

| Problem | What to check |
| --- | --- |
| `Signing requires a development team` | Select your Personal Team in the target's Signing & Capabilities tab. |
| Bundle ID unavailable | Change the `org.example.*` identifier to a unique one. |
| A different iPhone is shown | You may be viewing a simulator. Connect and select your physical device. |
| Developer Mode is missing | Pair the unlocked iPhone with Xcode first, then check Privacy & Security again. |
| Xcode requires a newer macOS | Use an Apple-supported Xcode version for that Mac and device. |
| Google sign-in is blocked | This is an embedded-browser restriction, not a password issue solved by changing the user agent. |
| A filter stops working | The website may have changed. See `docs/TESTING.md` and report the exact reproducible issue. |

## What not to share

Never post your `.p12`, `.p8`, provisioning profiles, personal certificates, device diagnostic logs, login cookies, screenshots of private messages, or account credentials. This repository intentionally does not include signing state.
