//
//  BaseProfiles.swift
//  SBSwiftComponents
//
//  Created by nanhu on 2018/9/4.
//  Copyright © 2018年 nanhu. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Base Profile
class BaseProfile: UIViewController {
    
    // MARK: - override
    deinit {
        debugPrint("profile:\(type(of: self)) 析构")
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    init() {
        super.init(nibName: nil, bundle: nil)
        guard #available(iOS 11.0, *) else {
            self.automaticallyAdjustsScrollViewInsets = false
            return
        }
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        guard #available(iOS 11.0, *) else {
            self.automaticallyAdjustsScrollViewInsets = false
            return
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    // MARK: - Variables
    lazy var navigationBar: BaseNavigationBar = {
        let n = BaseNavigationBar()
        let tintColor = AppColor.COLOR_NAVIGATOR_TINT
        let barTintColor = UIColor.white //影响背景
        let font = AppFont.pingFangSC(AppFont.SIZE_LARGE_TITLE)
        n.barStyle = .black
        let bgImg = UIImage.pb_imageWithColor(barTintColor);
        n.setBackgroundImage(bgImg, for: .default)
        n.shadowImage = UIImage()
        n.barTintColor = barTintColor
        n.tintColor = tintColor
        n.isTranslucent = false
        n.titleTextAttributes = {[
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor:tintColor
            ]}()
        return n
    }()
    
    // MARK: - Inner-Methods
    func app() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    @objc public func defaultGobackStack() {
        guard self.isBeingPresented else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
    public func whetherContain(_ cls: String) -> Bool {
        guard let navi = self.navigationController else {
            return false
        }
        let stacks: [UIViewController] = navi.viewControllers
        var contain: Bool = false
        for (_, p) in stacks.enumerated() {
            let clsString = String(describing: type(of: p))
            if clsString == cls {
                contain = true
                break
            }
        }
        return contain
    }
}

// MARK: - Base NavigationController
class BaseNavigationProfile: UINavigationController {
    /// override
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let top = self.topViewController else {
            return .default
        }
        return top.preferredStatusBarStyle
    }
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
    
    override var shouldAutorotate: Bool {
        return (topViewController?.shouldAutorotate)!
    }
    //支持旋转的方向有哪些
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return (topViewController?.supportedInterfaceOrientations)!
    }
    //控制 vc present进来的横竖屏和进入方向 ，支持的旋转方向必须包含改返回值的方向 （详细的说明见下文）
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return (topViewController?.preferredInterfaceOrientationForPresentation)!
    }
}
extension UINavigationController {
    func app() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    public func defaultGoBack(_ excute: DelayedClosure? = nil) {
        let statcks = self.viewControllers
        if statcks.count <= 1 {
            guard let rooter = self.app().window?.rootViewController else {
                self.dismiss(animated: true, completion: excute)
                return
            }
            if self != rooter {
                self.dismiss(animated: true, completion: excute)
            }
        } else {
            // 初始化动画的持续时间，类型和子类型
            UIView.animate(withDuration: Macros.APP_ANIMATE_INTERVAL, animations: {[weak self]in
                self?.popViewController(animated: true)
            }) { (finish) in
                excute?()
            }
        }
    }
}

// MARK: - Base TabBarController
class BaseTabBarProfile: UITabBarController {
    
    /// override
    //是否跟随屏幕旋转
    override var shouldAutorotate : Bool {
        return (selectedViewController?.shouldAutorotate)!
    }
    //支持旋转的方向有哪些
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return (selectedViewController?.supportedInterfaceOrientations)!
    }
    //控制 vc present进来的横竖屏和进入方向 ，支持的旋转方向必须包含改返回值的方向 （详细的说明见下文）
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return (selectedViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    /// hide bar
    private func isTabBarHidden() -> Bool {
        return self.tabBar.isHidden
    }
    
    public func hideBar(_ hide: Bool, animate: Bool) {
        guard hide != self.isTabBarHidden() else {
            return
        }
        var transitionView: UIView?
        if let first = self.view.subviews.first, first.isKind(of: UITabBar.self) {
            transitionView = first
        } else {
            transitionView = self.view.subviews.first
        }
        if !hide {
            self.tabBar.isHidden = hide
        }
        self.pb_isTabBarAnimating = true
        
        UIView.animate(withDuration: animate ? TimeInterval(UINavigationControllerHideShowBarDuration) : 0, delay: 0, options: .allowUserInteraction, animations: {
            var tabBarTop: CGFloat = 0
            let viewFrame = self.view.convert(self.view.bounds, to: self.tabBar.superview)
            if hide {
                tabBarTop = viewFrame.origin.y + viewFrame.size.height
                transitionView?.frame = self.view.bounds
            } else {
                let bounds = self.view.bounds
                let selfHeight = self.tabBar.frame.size.height
                tabBarTop = viewFrame.origin.y + viewFrame.size.height - selfHeight
                transitionView?.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height - selfHeight)
            }
            var frame:CGRect = self.tabBar.frame
            frame.origin.y = tabBarTop
            self.tabBar.frame = frame
        }) { [weak self](f: Bool) in
            if hide {
                self?.tabBar.isHidden = true
            }
            self?.pb_isTabBarAnimating = false
        }
    }
}
extension BaseTabBarProfile {
    private struct pb_tabbarHiddenKeys {
        static var pb_isTabBarAnimating = "pb_isTabBarAnimating"
    }
    
    private var pb_isTabBarAnimating: Bool {
        get {
            return objc_getAssociatedObject(self, &pb_tabbarHiddenKeys.pb_isTabBarAnimating) as! Bool
        }
        
        set {
            objc_setAssociatedObject(self, &pb_tabbarHiddenKeys.pb_isTabBarAnimating, newValue as Bool, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}