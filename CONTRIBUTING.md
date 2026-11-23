# Contributing

Thanks for considering a contribution. This repository is a small educational iOS project; contributions should be focused, reproducible and respectful of user privacy.

## Before opening a pull request

1. Check whether the problem is already documented in `docs/LIMITATIONS.md` or existing issues.
2. Create a small branch with a descriptive name.
3. Keep changes limited to one feature or bug per pull request.
4. Run `python3 scripts/check_repo.py` and, when on a Mac, build each Xcode project for iOS Simulator.
5. Add manual reproduction steps and specify exactly which website UI behaviour changed.
6. Do not include login credentials, cookies, screenshots containing private chats, or signing details.

## Coding conventions

- Prefer readable SwiftUI views and named helpers over large repeated inline expressions.
- Keep JavaScript filters narrow to reduce accidental hiding of unrelated posts or videos.
- Maintain the website's own menu; do not add a second bottom bar.
- Avoid undocumented authentication workarounds or private Instagram/Google endpoints.
- Document assumptions, limitations and behaviour that has not yet been tested.

By contributing, you agree that your original changes may be distributed under the repository's MIT License.
