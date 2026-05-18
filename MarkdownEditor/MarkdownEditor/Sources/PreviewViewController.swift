import Cocoa
import WebKit

@objc(PreviewViewController)
class PreviewViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {
    private static let aboutScheme = "about"
    private static let httpScheme = "http"
    private static let httpsScheme = "https"

    @IBOutlet weak var webView: WKWebView!

    @objc var navigation: WKNavigation?
    private var visibleRect = NSRect.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        replacePreviewWebViewWithLockedDownConfiguration()
        view.setAccessibilityIdentifier("PreviewPane")
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        webView.setAccessibilityIdentifier("PreviewWebView")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeContentNotification(_:)),
            name: ConverterManager.didChangeContentNotification,
            object: nil
        )

        visibleRect = .zero
        reloadHtml()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.scrollToVisible(visibleRect)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = navigationAction.request.url
        if navigationAction.navigationType == .linkActivated, isExternalPreviewNavigationURL(url) {
            if let url {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(isAllowedPreviewNavigationURL(url) ? .allow : .cancel)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let url = navigationAction.request.url
        if navigationAction.navigationType == .linkActivated, isExternalPreviewNavigationURL(url), let url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }

    @objc func didChangeContentNotification(_ notification: Notification?) {
        reloadHtml()
    }

    private func replacePreviewWebViewWithLockedDownConfiguration() {
        guard let storyboardWebView = webView, let superview = storyboardWebView.superview else {
            return
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let lockedDownWebView = WKWebView(frame: storyboardWebView.frame, configuration: configuration)
        lockedDownWebView.autoresizingMask = storyboardWebView.autoresizingMask
        lockedDownWebView.translatesAutoresizingMaskIntoConstraints = storyboardWebView.translatesAutoresizingMaskIntoConstraints
        lockedDownWebView.navigationDelegate = self
        lockedDownWebView.uiDelegate = self

        let index = superview.subviews.firstIndex(of: storyboardWebView)
        storyboardWebView.removeFromSuperview()
        let relativeView = index.flatMap { $0 < superview.subviews.count ? superview.subviews[$0] : nil }
        superview.addSubview(lockedDownWebView, positioned: .below, relativeTo: relativeView)
        webView = lockedDownWebView
    }

    @objc func reloadHtml() {
        visibleRect = webView.visibleRect
        let html = lockedDownPreviewHTML(withHTML: ConverterManager.shared.html)
        navigation = webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    @objc(lockedDownPreviewHTMLWithHTML:)
    func lockedDownPreviewHTML(withHTML html: String?) -> String {
        let contentSecurityPolicy = "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src file:; style-src file: 'unsafe-inline'; script-src file: 'unsafe-inline'; font-src file:; connect-src 'none'; frame-src 'none'; media-src file:\">"
        guard let html else {
            return contentSecurityPolicy
        }
        guard let headEndRange = html.range(of: "</head>", options: .caseInsensitive) else {
            return contentSecurityPolicy + html
        }

        var lockedDownHTML = html
        lockedDownHTML.insert(contentsOf: contentSecurityPolicy, at: headEndRange.lowerBound)
        return lockedDownHTML
    }

    @objc func isAllowedPreviewNavigationURL(_ url: URL?) -> Bool {
        guard let url else {
            return true
        }
        if url.scheme == Self.aboutScheme {
            return true
        }
        guard url.isFileURL else {
            return false
        }

        let resourceURL = Bundle.main.resourceURL?.standardizedFileURL
        let standardizedURL = url.standardizedFileURL
        guard let resourcePath = resourceURL?.path else {
            return false
        }
        let urlPath = standardizedURL.path
        return urlPath == resourcePath || urlPath.hasPrefix(resourcePath + "/")
    }

    @objc func isExternalPreviewNavigationURL(_ url: URL?) -> Bool {
        let scheme = url?.scheme?.lowercased()
        return scheme == Self.httpScheme || scheme == Self.httpsScheme
    }

    @IBAction func reloadButtonClicked(_ sender: NSButton?) {
        reloadHtml()
    }
}
