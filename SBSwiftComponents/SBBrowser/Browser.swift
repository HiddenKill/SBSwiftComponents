//
//  Browser.swift
//  SBSwiftComponents
//
//  Created by nanhu on 2018/9/12.
//  Copyright © 2018年 nanhu. All rights reserved.
//

import WebKit
import Foundation

public protocol SBWebDelegate: class {
    func didStartLoading()
    func ddiFinishedLoad(success: Bool)
}

public class WebBrowser: BaseProfile, WKUIDelegate, WKNavigationDelegate {
    
    /// -- Variables
    private lazy var webView: WKWebView = {
        var w = WKWebView(frame: .zero)
        w.uiDelegate = self
        w.navigationDelegate = self
        w.addObserver(self, forKeyPath: "estimatedProgress", options: [.new], context: nil)
        w.scrollView.addSubview(sourceLab)
        return w
    }()
    private lazy var progress: UIProgressView = {
        let p = UIProgressView(frame: .zero)
        p.tintColor = UIColor.green
        p.trackTintColor = UIColor.white//底色
        p.progress = 0
        return p
    }()
    private lazy var sourceLab: UILabel = {
        let sb = CGRect(x: 0, y: -AppSize.HEIGHT_CELL, width: AppSize.WIDTH_SCREEN, height: AppSize.HEIGHT_CELL)
        let l = UILabel(frame: sb)
        l.font = AppFont.pingFangSC(AppFont.SIZE_SUB_TITLE)
        l.textColor = AppColor.COLOR_TITLE_GRAY
        l.textAlignment = .center
        l.text = "此网页由 x16.com 提供"
        return l
    }()
    
    private lazy var navigatorItem: UINavigationItem = {
        var title: String = ""
        if let p = params, p.keys.contains("title") {
            title = p["title"] as! String
        }
        let i = UINavigationItem(title: title)
        return i
    }()
    private weak var delegate: SBWebDelegate?
    private var params: SBSceneRouteParameter?
    init(_ parameters: SBSceneRouteParameter?) {
        params = parameters
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    var storedStatusColor: UIBarStyle?
    var buttonColor: UIColor? = nil
    var titleColor: UIColor? = nil
    var closing: Bool! = false
    var request: URLRequest!
    var sharingEnabled = true
    
    /// getters
    lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: WebBrowser.bundledImage(named: "browser_icon_back"),
                                                    style: UIBarButtonItemStyle.plain,
                                                    target: self,
                                                    action: #selector(goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()
    
    lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: WebBrowser.bundledImage(named: "browser_icon_forward"),
                                                       style: UIBarButtonItemStyle.plain,
                                                       target: self,
                                                       action: #selector(goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()
    
    lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh,
                                                       target: self,
                                                       action: #selector(reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = self.buttonColor
        return tempRefreshBarButtonItem
    }()
    
    lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop,
                                                    target: self,
                                                    action: #selector(stopTapped(_:)))
        tempStopBarButtonItem.tintColor = self.buttonColor
        return tempStopBarButtonItem
    }()
    
    lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action,
                                                      target: self,
                                                      action: #selector(actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = self.buttonColor
        return tempActionBarButtonItem
    }()
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @objc func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @objc func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }
    
    @objc func actionButtonTapped(_ sender: AnyObject) {
        
        if let url: URL = ((webView.url != nil) ? webView.url : request.url) {
            let activities: NSArray = [SBActivitySafari(), SBActivityChrome()]
            
            if url.absoluteString.hasPrefix("file:///") {
                let dc: UIDocumentInteractionController = UIDocumentInteractionController(url: url)
                dc.presentOptionsMenu(from: view.bounds, in: view, animated: true)
            }
            else {
                let activityController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: activities as? [UIActivity])
                
                if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    let ctrl: UIPopoverPresentationController = activityController.popoverPresentationController!
                    ctrl.sourceView = view
                    ctrl.barButtonItem = sender as? UIBarButtonItem
                }
                
                present(activityController, animated: true, completion: nil)
            }
        }
    }
    
    /// progress
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let o = object as? WKWebView else {
            return
        }
        if o == self.webView && keyPath == "estimatedProgress" {
            let np = webView.estimatedProgress
            debugPrint("progress:\(np)")
            progress.isHidden =  np >= 1
            progress.progress = np >= 1 ? 0 : Float(np)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func doneButtonTapped() {
        closing = true
        UINavigationBar.appearance().barStyle = storedStatusColor!
        self.dismiss(animated: true, completion: nil)
    }
    
    class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(named: named, in: Bundle(for: WebBrowser.classForCoder()), compatibleWith: nil)
        } // Replace MyBasePodClass with yours
        return image
    }
}

// MARK: - UI-Layouts
extension WebBrowser {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        /// navigation bar
        view.addSubview(navigationBar)
        let spacer = Kits.barSpacer()
        let backer = Kits.defaultBackBarItem(self, action: #selector(defaultGobackStack))
        navigatorItem.leftBarButtonItems = [spacer, backer]
        navigationBar.pushItem(navigatorItem, animated: true)
        
        /// webview
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
        
        /// progress
        view.addSubview(progress)
        progress.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        
        /// request
        if let p = params, p.keys.contains("url") {
            let urlString = p["url"] as! String
            guard (urlString.hasPrefix("http://")||urlString.hasPrefix("https://")||urlString.hasPrefix("www")) else {
                if urlString.hasPrefix("/Users/") || urlString.hasPrefix("/var/mobile/") {
                    loadLocalFile(urlString)
                } else {
                    loadContentString(urlString)
                }
                return
            }
            var uri: URL?
            if urlString.hasPrefix("www") {
                uri = URL(string: "https://"+urlString)
            } else {
                uri = URL(string: urlString)
            }
            guard let url = uri else {
                loadContentString(urlString)
                return
            }
            request = URLRequest(url: url)
        }
        webView.load(request)
    }
    private func loadLocalFile(_ path: String) {
        let uri = URL(fileURLWithPath: path)
        let root = Kits.locatePath(.file)
        let rootUri = URL(fileURLWithPath: root)
        webView.loadFileURL(uri, allowingReadAccessTo: rootUri)
    }
    private func loadContentString(_ info: String) {
        let header = "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/><meta  name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\"/></head>"
        let body = "<body style='width:100%;background-color:white;padding:0px;margin:0px;display:block;'>"
        let div = "<div id='myid' style = 'width:100%;height:10px;background-color:white;display:block'></div>"
        let html = String(format: "<html> %@ %@ %@ </body></html>", header, body, info, div)
        webView.loadHTMLString(html, baseURL: nil)
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateToolbarItems()
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func updateToolbarItems() {
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let refreshStopBarButtonItem: UIBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            
            let toolbarWidth: CGFloat = 250.0
            fixedSpace.width = 35.0
            
            let items: NSArray = sharingEnabled ? [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem, fixedSpace, actionBarButtonItem] : [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem]
            
            let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: toolbarWidth, height: 44.0))
            if !closing {
                toolbar.items = items as? [UIBarButtonItem]
                if presentingViewController == nil {
                    toolbar.barTintColor = navigationController!.navigationBar.barTintColor
                } else {
                    toolbar.barStyle = navigationController!.navigationBar.barStyle
                }
                toolbar.tintColor = navigationController!.navigationBar.tintColor
            }
            navigationItem.rightBarButtonItems = items.reverseObjectEnumerator().allObjects as? [UIBarButtonItem]
            
        } else {
            let items: NSArray = sharingEnabled ? [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, actionBarButtonItem, fixedSpace] : [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, fixedSpace]
            
            if let navigationController = navigationController, !closing {
                if presentingViewController == nil {
                    navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                } else {
                    navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
                }
                navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                toolbarItems = items as? [UIBarButtonItem]
            }
        }
    }
}

extension WebBrowser {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.delegate?.didStartLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
        if let host = webView.url?.host {
            let source = "此网页由 \(host) 提供"
            sourceLab.text = source
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.ddiFinishedLoad(success: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        webView.evaluateJavaScript("document.title", completionHandler: {(response, error) in
            self.navigatorItem.title = response as! String?
            self.updateToolbarItems()
        })
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.ddiFinishedLoad(success: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let url = navigationAction.request.url
        
        let hostAddress = navigationAction.request.url?.host
        
        if (navigationAction.targetFrame == nil) {
            if UIApplication.shared.canOpenURL(url!) {
                //UIApplication.shared.openURL(url!)
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        }
        
        // To connnect app store
        if hostAddress == "itunes.apple.com" {
            if UIApplication.shared.canOpenURL(navigationAction.request.url!) {
                //UIApplication.shared.openURL(navigationAction.request.url!)
                UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        
        let url_elements = url!.absoluteString.components(separatedBy: ":")
        
        switch url_elements[0] {
        case "tel":
            openCustomApp(urlScheme: "telprompt://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "sms":
            openCustomApp(urlScheme: "sms://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "mailto":
            openCustomApp(urlScheme: "mailto://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        default:
            //print("Default")
            break
        }
        
        decisionHandler(.allow)
        
    }
    
    func openCustomApp(urlScheme: String, additional_info:String){
        
        if let requestUrl: URL = URL(string:"\(urlScheme)"+"\(additional_info)") {
            let application:UIApplication = UIApplication.shared
            if application.canOpenURL(requestUrl) {
                //application.openURL(requestUrl)
                application.open(requestUrl, options: [:], completionHandler: nil)
            }
        }
    }
}

// MARK: - Router Ext
extension WebBrowser: SBSceneRouteable {
    public static func __init(_ params: SBSceneRouteParameter?) -> UIViewController {
        return WebBrowser(params)
    }
}
