import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("tubeHideHomeFeed") private var hideHomeFeed = false
    @State private var webView: WKWebView?
    @State private var showSettings = false
    @State private var showBlockedAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lock In Tube")
                    .font(.headline)
                Spacer()
                Button {
                    webView?.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Reload YouTube")
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            YouTubeWebView(
                webView: $webView,
                hideHomeFeed: hideHomeFeed,
                onBlockedShort: { showBlockedAlert = true }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Section("Filters") {
                        LabeledContent("YouTube Shorts", value: "Always blocked")
                        LabeledContent("Community posts", value: "Hidden in feeds")
                        Toggle("Hide Home recommendations", isOn: $hideHomeFeed)
                    }
                    Section {
                        Text("Shorts and Community posts are filtered. YouTube's original menu remains. Home recommendation changes apply after reloading.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Reload YouTube") {
                            showSettings = false
                            webView?.reload()
                        }
                    }
                }
                .navigationTitle("Lock In Tube")
                .toolbar {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .alert("Shorts blocked", isPresented: $showBlockedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Lock In Tube doesn't open YouTube Shorts.")
        }
    }
}

private struct YouTubeWebView: UIViewRepresentable {
    @Binding var webView: WKWebView?
    let hideHomeFeed: Bool
    let onBlockedShort: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBlockedShort: onBlockedShort)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        config.userContentController.addUserScript(
            WKUserScript(
                source: filterJavaScript(hideHomeFeed: hideHomeFeed),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
        context.coordinator.installedHideHome = hideHomeFeed

        DispatchQueue.main.async {
            self.webView = view
        }

        view.load(URLRequest(url: URL(string: "https://m.youtube.com/")!))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onBlockedShort = onBlockedShort
        if context.coordinator.installedHideHome != hideHomeFeed {
            uiView.configuration.userContentController.removeAllUserScripts()
            uiView.configuration.userContentController.addUserScript(
                WKUserScript(
                    source: filterJavaScript(hideHomeFeed: hideHomeFeed),
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
            context.coordinator.installedHideHome = hideHomeFeed
        }
        uiView.evaluateJavaScript(
            filterJavaScript(hideHomeFeed: hideHomeFeed),
            completionHandler: nil
        )
    }

    private func filterJavaScript(hideHomeFeed: Bool) -> String {
        let hideHome = hideHomeFeed ? "true" : "false"
        return #"""
        (() => {
          // Never inspect or modify Google sign-in pages or other websites.
          const host = location.hostname.toLowerCase();
          if (host !== 'youtube.com' && !host.endsWith('.youtube.com')) return;

          const isShort = path => /^\/shorts(?:\/|$)/i.test(path);
          const pathOf = url => {
            try { return new URL(url, location.href).pathname; }
            catch (_) { return ''; }
          };
          const settings = window.__lockInTubeSettings || {};
          settings.hideHome = \#(hideHome);
          window.__lockInTubeSettings = settings;

          // In-app navigation can bypass the iOS navigation delegate.
          if (!window.__lockInTubeInstalled) {
            window.__lockInTubeInstalled = true;

            document.addEventListener('click', event => {
              const link = event.target.closest?.('a[href]');
              if (link && isShort(pathOf(link.href))) {
                event.preventDefault();
                event.stopImmediatePropagation();
              }
            }, true);

            for (const method of ['pushState', 'replaceState']) {
              const original = history[method];
              history[method] = function(...args) {
                if (args[2] && isShort(pathOf(args[2]))) return;
                return original.apply(this, args);
              };
            }
          }

          const hide = el => {
            if (el) el.style.setProperty('display', 'none', 'important');
          };

          const clean = () => {
            // Hide community picture, carousel, poll and text posts in feeds.
            // Avoid altering watch pages, comments, and channel-specific content.
            const inFeed = location.pathname === '/' ||
              location.pathname === '/feed/home' ||
              location.pathname === '/feed/subscriptions';
            if (inFeed) {
              const postSelector = [
                'ytm-post-renderer',
                'ytm-post-card-renderer',
                'ytm-backstage-post-renderer',
                'ytm-backstage-post-thread-renderer',
                'ytd-post-renderer',
                'ytd-backstage-post-thread-renderer',
                'ytd-rich-item-renderer[is-post]'
              ].join(', ');

              document.querySelectorAll(postSelector).forEach(post => {
                const card = post.closest(
                  'ytm-rich-item-renderer, ytd-rich-item-renderer'
                );
                hide(card || post);
              });
              document.querySelectorAll('a[href]').forEach(link => {
                if (!/^\/post(?:\/|$)/i.test(pathOf(link.getAttribute('href')))) return;
                const card = link.closest(
                  'ytm-rich-item-renderer, ytd-rich-item-renderer, ' +
                  'ytm-rich-section-renderer, ytd-rich-section-renderer'
                );
                if (card) {
                  const regularVideo = card.querySelector(
                    'a[href*="/watch?"], a[href*="/live/"]'
                  );
                  if (!regularVideo) hide(card);
                } else {
                  hide(link);
                }
              });
            }

            // Hide known Shorts shelves and standalone Shorts cards.
            document.querySelectorAll(
              'ytm-reel-shelf-renderer, ytd-reel-shelf-renderer, ' +
              'ytm-shorts-lockup-view-model, ytm-reel-item-renderer, ' +
              'ytd-reel-item-renderer'
            ).forEach(hide);

            document.querySelectorAll('a[href]').forEach(link => {
              if (!isShort(pathOf(link.getAttribute('href')))) return;

              // Remove the Shorts tab without hiding YouTube's whole menu.
              const nav = link.closest(
                'ytm-pivot-bar-item-renderer, ytm-guide-entry-renderer, ' +
                'ytd-guide-entry-renderer, ytd-mini-guide-entry-renderer'
              );
              if (nav) { hide(nav); return; }

              // Remove individual Shorts results, not normal video cards.
              const card = link.closest(
                'ytm-shorts-lockup-view-model, ytm-video-with-context-renderer, ' +
                'ytm-compact-video-renderer, ytm-rich-item-renderer, ' +
                'ytd-rich-item-renderer, ytd-video-renderer, ytd-grid-video-renderer'
              );
              if (card) hide(card);
              else hide(link);
            });

            // Remove mixed-layout shelves only when clearly Shorts-only.
            document.querySelectorAll(
              'ytm-rich-shelf-renderer, ytd-rich-shelf-renderer'
            ).forEach(shelf => {
              const shortLinks = shelf.querySelectorAll('a[href*="/shorts/"]');
              const regularLinks = shelf.querySelectorAll('a[href*="/watch?"]');
              if (shortLinks.length > 0 && regularLinks.length === 0) hide(shelf);
            });

            // Some menus use buttons instead of anchor links.
            document.querySelectorAll(
              'ytm-pivot-bar-item-renderer, ytm-guide-entry-renderer'
            ).forEach(item => {
              const label = (item.getAttribute('aria-label') || item.textContent || '').trim();
              if (/^shorts$/i.test(label)) hide(item);
            });

            if (settings.hideHome && (location.pathname === '/' ||
                location.pathname === '/feed/home')) {
              document.querySelectorAll(
                'ytm-rich-grid-renderer, ytd-rich-grid-renderer, ' +
                'ytm-section-list-renderer'
              ).forEach(hide);
            }

            // A Shorts URL might be reached through YouTube's SPA router.
            if (isShort(location.pathname)) {
              location.replace('https://m.youtube.com/');
            }
          };

          if (!window.__lockInTubeObserver) {
            let scheduled = false;
            window.__lockInTubeObserver = new MutationObserver(() => {
              if (scheduled) return;
              scheduled = true;
              requestAnimationFrame(() => {
                scheduled = false;
                clean();
              });
            });
            window.__lockInTubeObserver.observe(document.documentElement,
              { childList: true, subtree: true });

            document.addEventListener('yt-navigate-finish', clean);
            window.addEventListener('popstate', clean);
          }
          clean();
        })();
        """#
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onBlockedShort: () -> Void
        var installedHideHome: Bool? = nil

        init(onBlockedShort: @escaping () -> Void) {
            self.onBlockedShort = onBlockedShort
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                let host = url.host?.lowercased() ?? ""
                let isYouTube = host == "youtube.com" || host.hasSuffix(".youtube.com")
                if !isYouTube {
                    // Google sign-in in embedded WKWebView is restricted.
                    // Open other sites in Safari rather than injecting into them.
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
                if url.path.range(of: "^/shorts(/|$)", options: .regularExpression) != nil {
                    onBlockedShort()
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                let host = url.host?.lowercased() ?? ""
                if host == "youtube.com" || host.hasSuffix(".youtube.com") {
                    if url.path.range(of: "^/shorts(/|$)", options: .regularExpression) != nil {
                        onBlockedShort()
                    } else {
                        webView.load(URLRequest(url: url))
                    }
                } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    UIApplication.shared.open(url)
                }
            }
            return nil
        }
    }
}
