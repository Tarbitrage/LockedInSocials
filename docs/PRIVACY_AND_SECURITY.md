# Privacy and security

These are personal-use prototypes, **not independently security-audited apps**.

## Data handling in this repository

- No custom server, analytics SDK, advertising SDK, account database, or built-in credential collection.
- The embedded `WKWebView` loads the third-party service, which can set its own cookies and collect information under its own policies.
- WebKit's default website data store may retain login sessions locally on the device.
- Filter preferences are saved on-device with `@AppStorage`.
- There is no application feature for exporting messages, browsing history or account information.

## Critical caveat about embedded logins

An app that controls a `WKWebView` has the technical ability to run JavaScript inside the webpages it loads. This can create credential and session-security risks. **Do not treat a familiar-looking login page inside a third-party app as equivalent to Safari's isolated login flow.** Inspect the source and assess the risk before logging into an important account.

Google may block sign-in from embedded browsers. These apps do not attempt to bypass Google's account security restrictions.

## Source-code publication checklist

Before committing any changes, search for:

- Personal names, emails, usernames, local home-directory paths or device identifiers.
- Apple Development Team IDs, private signing keys, provisioning profiles and certificates.
- Tokens, passwords, session cookies, API secrets, `.env` files or web debugging snapshots.
- Screenshots with account names, personal messages, photos or notifications.
- Telemetry, unexpected network destinations or newly introduced dependencies.

`.gitignore` blocks common local files, but it is **not a substitute for a manual secrets review**. Deleting a secret in a later commit does not remove it from Git history.

## Vulnerability reporting

Please do not publish proof-of-concept credential theft or private user data in public issues. See [`SECURITY.md`](../SECURITY.md) for private reporting guidance.
