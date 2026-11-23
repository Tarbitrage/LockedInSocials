import SwiftUI
import WebKit

// Personal-use Instagram website wrapper. This file contains no credentials,
// analytics, custom servers or personal identifiers.
struct ContentView: View {
    @AppStorage("hideExplore") private var hideExplore = false
    @AppStorage("hideSuggested") private var hideSuggested = true

    @State private var webView: WKWebView?
    @State private var showSettings = false
    @State private var showBlocked = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lock In Gram")
                    .font(.headline)
                Spacer()
                Button { webView?.reload() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Reload Instagram")

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // The website's own navigation stays visible. No native bottom bar.
            InstagramWebView(
                webView: $webView,
                hideExplore: hideExplore,
                hideSuggested: hideSuggested,
                onBlocked: { showBlocked = true }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Toggle("Hide Explore", isOn: $hideExplore)
                    Toggle("Hide suggested posts", isOn: $hideSuggested)

                    Section {
                        Text("Reel URLs are blocked. Instagram's website may change, so filtering is best-effort.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Reload Instagram") {
                            showSettings = false
                            webView?.reload()
                        }
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .alert("Reels blocked", isPresented: $showBlocked) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Lock In Gram does not open Reel pages.")
        }
    }
}

private struct InstagramWebView: UIViewRepresentable {
    @Binding var webView: WKWebView?
    let hideExplore: Bool
    let hideSuggested: Bool
    let onBlocked: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBlocked: onBlocked)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: filterScript(hideExplore: hideExplore, hideSuggested: hideSuggested),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
        context.coordinator.webView = view

        DispatchQueue.main.async {
            self.webView = view
        }
        view.load(URLRequest(url: URL(string: "https://www.instagram.com/")!))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onBlocked = onBlocked
        context.coordinator.hideExplore = hideExplore
        context.coordinator.hideSuggested = hideSuggested
        // Keep the injected startup script consistent on future page loads.
        let newSettings = "\(hideExplore)-\(hideSuggested)"
        if context.coordinator.installedSettings != newSettings {
            uiView.configuration.userContentController.removeAllUserScripts()
            uiView.configuration.userContentController.addUserScript(
                WKUserScript(
                    source: filterScript(hideExplore: hideExplore, hideSuggested: hideSuggested),
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
            context.coordinator.installedSettings = newSettings
        }
        uiView.evaluateJavaScript(
            filterScript(hideExplore: hideExplore, hideSuggested: hideSuggested),
            completionHandler: nil
        )
    }

    // JavaScript runs only on Instagram, never on external login pages.
    private func filterScript(hideExplore: Bool, hideSuggested: Bool) -> String {
        let explore = hideExplore ? "true" : "false"
        let suggested = hideSuggested ? "true" : "false"
        return #"""
        (() => {
          const host = location.hostname.toLowerCase();
          if (host !== 'instagram.com' && !host.endsWith('.instagram.com')) return;

          const options = window.__lockInGramOptions || {};
          options.hideExplore = \#(explore);
          options.hideSuggested = \#(suggested);
          window.__lockInGramOptions = options;

          const isReel = path => /^\/reels?(\/|$)/i.test(path);
          const getPath = href => {
            try { return new URL(href, location.href).pathname; }
            catch (_) { return ''; }
          };
          const hide = element => {
            if (element) element.style.setProperty('display', 'none', 'important');
          };

          const clean = () => {
            const inMessages = location.pathname.startsWith('/direct/');
            document.querySelectorAll('a[href]').forEach(link => {
              const path = getPath(link.href);
              const reelLink = isReel(path);
              const exploreLink = options.hideExplore && path.startsWith('/explore/');
              if ((reelLink && !inMessages) || exploreLink) {
                const article = reelLink ? link.closest('article') : null;
                // Leave Reel previews in DMs intact so chat media is not hidden.
                hide(article || link);
              }
            });

            if (options.hideSuggested) {
              document.querySelectorAll('article').forEach(article => {
                const text = (article.innerText || '').slice(0, 250).toLowerCase();
                if (text.includes('suggested for you') || text.includes('suggested post')) {
                  hide(article);
                }
              });
            }

            if (isReel(location.pathname) ||
                (options.hideExplore && location.pathname.startsWith('/explore/'))) {
              location.replace('https://www.instagram.com/');
            }
          };

          if (!window.__lockInGramInstalled) {
            window.__lockInGramInstalled = true;
            document.addEventListener('click', event => {
              const link = event.target.closest?.('a[href]');
              if (!link) return;
              const path = getPath(link.href);
              if (isReel(path) || (options.hideExplore && path.startsWith('/explore/'))) {
                event.preventDefault();
                event.stopImmediatePropagation();
              }
            }, true);

            for (const method of ['pushState', 'replaceState']) {
              const original = history[method];
              history[method] = function(...args) {
                const path = args[2] ? getPath(args[2]) : '';
                if (isReel(path) || (options.hideExplore && path.startsWith('/explore/'))) return;
                return original.apply(this, args);
              };
            }

            let scheduled = false;
            new MutationObserver(() => {
              if (scheduled) return;
              scheduled = true;
              requestAnimationFrame(() => { scheduled = false; clean(); });
            }).observe(document.documentElement, { childList: true, subtree: true });
            window.addEventListener('popstate', clean);
          }
          clean();
        })();
        """#
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onBlocked: () -> Void
        weak var webView: WKWebView?
        var hideExplore = false
        var hideSuggested = true
        var installedSettings: String? = nil

        init(onBlocked: @escaping () -> Void) {
            self.onBlocked = onBlocked
        }

        private func isBlocked(_ url: URL) -> Bool {
            let host = url.host?.lowercased() ?? ""
            guard host == "instagram.com" || host.hasSuffix(".instagram.com") else { return false }
            let path = url.path
            let reel = path.range(of: "^/reels?(/|$)", options: .regularExpression) != nil
            let explore = hideExplore && path.hasPrefix("/explore/")
            return reel || explore
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else {
                decisionHandler(.cancel)
                return
            }
            if isBlocked(url) {
                onBlocked()
                decisionHandler(.cancel)
                return
            }
            if let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                let host = url.host?.lowercased() ?? ""
                let allowed = host == "instagram.com" || host.hasSuffix(".instagram.com") ||
                    host == "facebook.com" || host.hasSuffix(".facebook.com") ||
                    host == "meta.com" || host.hasSuffix(".meta.com")
                if !allowed {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard navigationAction.targetFrame == nil,
                  let url = navigationAction.request.url else { return nil }
            if isBlocked(url) {
                onBlocked()
            } else {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
