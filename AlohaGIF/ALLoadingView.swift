 //
 //  ALLoadingView.swift
 //
 //  Copyright (c) 2015-2017 Artem Loginov
 //
 //  Permission is hereby granted, free of charge, to any person obtaining a copy
 //  of this software and associated documentation files (the "Software"), to deal
 //  in the Software without restriction, including without limitation the rights
 //  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 //  copies of the Software, and to permit persons to whom the Software is
 //  furnished to do so, subject to the following conditions:
 //
 //  The above copyright notice and this permission notice shall be included in
 //  all copies or substantial portions of the Software.
 //
 //  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 //  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 //  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 //  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 //  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 //  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 //  THE SOFTWARE.
 //

import UIKit

/// The closure called when loading view is presented or removed from screen.
public typealias ALLVCompletionBlock = () -> Void
 
/// The closure is called when cancel button is tapped
public typealias ALLVCancelBlock = () -> Void

private let kALLoadingViewDebugModeKey = false

/// Loading view types definitions
public enum ALLVType {
    /// Loading view with UIActivityIndicatorView, .white style, in the center.
    case basic
    
    /// Loading view with UITextView in the center for representing message (specified by `messageText`).
    case message
    
    /// Loading view with UIActivityIndicatorView and UITextView for representing message (specified by `messageText`).
    case messageWithIndicator
    
    /// Loading view with UIActivityIndicatorView, UITextView and simple UIButton. Button action is specified by `cancelCallback` property.
    case messageWithIndicatorAndCancelButton
    
    /// Loading view with UITextView and UIProgressView
    case progress
    
    /// Loading view with UITextView, UIProgressView and simple UIButton. Button action is specified by `cancelCallback` property.
    case progressWithCancelButton
}

/// Loading view size modes
public enum ALLVWindowMode {
    /// Loading view will take fullscreen. Content is centered.
    case fullscreen
    
    /// Loading view will take only part of the screen. Specified by `windowRatio`.
    case windowed
}

private enum ALLVProgress {
    case hidden
    case initializing
    case viewReady
    case loaded
    case hiding
}

// building blocks
private enum ALLVViewType {
    case blankSpace
    case messageTextView
    case progressBar
    case cancelButton
    case activityIndicator
}

/// `ALLoadingView` is a class for displaying pop-up views to notify users that some work is in progress.
///
/// For operating loading views and editing attributes use shared entity `manager`. For supporting different 
/// appearances and layouts use `-resetToDefaults()` method before setting up options for each case.
public class ALLoadingView: NSObject {
    //MARK: - Public variables
    /// Duration of loading view's appearance/disappearance animation. 0.5 seconds by default.
    public var animationDuration: TimeInterval = 0.5
    /// Spacing between loading view elements. 20 px by default.
    public var itemSpacing: CGFloat = 20.0
    /// Corner radius of loading view. Visible for `windowed` window mode. 0 by default.
    public var cornerRadius: CGFloat = 0.0
    /// Callback for cancel button.
    public var cancelCallback: ALLVCancelBlock?
    /// Flag for applying blur for background. False by default, `backgroundColor` is used.
    public var blurredBackground: Bool = false
    /// Background color for loading view if `blurredBackground` is disabled.
    public lazy var backgroundColor: UIColor = UIColor(white: 0.0, alpha: 0.5)
    /// Color of text message. White by default.
    public lazy var textColor: UIColor = UIColor(white: 1.0, alpha: 1.0)
    /// Font of message text view.
    public lazy var messageFont: UIFont = UIFont.systemFont(ofSize: 25.0)
    /// Text message. "Loading" by default.
    public lazy var messageText: String = "Loading"
    /// Read-only flag for checking is loading view is presented on screen. Also returns TRUE during disappearance/appearance animation.
    public var isPresented: Bool {
        return loadingViewPresented
    }
    
    // MARK: Size adjusments
    
    /// Determing size of loading view if `windowed` window mode is selected. Takes values from 0.3 to 1.0. Loading view will have height/width equal
    /// to 30% to 100% percent of minimum screen side respectively. Yes, fullscreen or square for now.
    public var windowRatio: CGFloat = 0.4 {
        didSet {
            windowRatio = min(max(0.3, windowRatio), 1.0)
        }
    }
    
    //MARK: - Private variables
    private var loadingViewPresented: Bool = false
    private var loadingViewProgress: ALLVProgress {
        didSet {
            if loadingViewProgress == .hidden {
                loadingViewPresented = false
            } else {
                loadingViewPresented = true
            }
        }
    }
    private var loadingViewType: ALLVType
    private var operationQueue = OperationQueue()
    private var blankIntrinsicContentSize = CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)
    // Subviews
    private var loadingView: UIView?
    private var appearanceView: UIView?
    private var stackView: UIStackView?
    
    //MARK: Custom setters/getters
    private var loadingViewWindowMode: ALLVWindowMode {
        didSet {
            if loadingViewWindowMode == .fullscreen {
                cornerRadius = 0.0
            } else  {
                blurredBackground = false
                if cornerRadius == 0.0 {
                    cornerRadius = 10.0
                }
            }
        }
    }
    
    private var frameForView: CGRect {
        if loadingViewWindowMode == .fullscreen || windowRatio == 1.0 {
            return UIScreen.main.bounds
        } else {
            let bounds = UIScreen.main.bounds;
            let size = min(bounds.width, bounds.height)
            return CGRect(x: 0, y: 0, width: size * windowRatio, height: size * windowRatio)
        }
    }
    
    private var isUsingBlurEffect: Bool {
        return self.loadingViewWindowMode == .fullscreen && self.blurredBackground
    }
    
    //MARK: - Initialization
    
    /// Creates a shared entity for operating loading views
    public class var manager: ALLoadingView {
        struct Singleton {
            static let instance = ALLoadingView()
        }
        return Singleton.instance
    }
    
    override init() {
        loadingViewWindowMode = .fullscreen
        loadingViewProgress = .hidden
        loadingViewType = .basic
    }
    
    // MARK: - Public methods
    // MARK: Show loading view
    
    /// Show loading view with selected type. Loading view will be added as a subview to main UIWindow in hierarchy. 
    ///
    /// - parameter type: Type of the loading view.
    /// - parameter windowMode: Type of window mode. Optional. `fullscreen` by default.
    /// - parameter completionBlock: The closure called when loading view is presented. Optional.
    public func showLoadingView(ofType type: ALLVType, windowMode: ALLVWindowMode? = nil, completionBlock: ALLVCompletionBlock? = nil) {
        guard loadingViewProgress == .hidden || loadingViewProgress == .hiding else {
            Logger.error("ALLoadingView Presentation Error. Trying to push loading view while there is one already presented")
            return
        }

        loadingViewProgress = .initializing
        loadingViewWindowMode = windowMode ?? .fullscreen
        loadingViewType = type
        
        let operationInit = BlockOperation { ()  -> Void in
            DispatchQueue.main.async {
                self.initializeLoadingView()
            }
        }
        
        let operationShow = BlockOperation { () -> Void in
            DispatchQueue.main.async {
                self.attachLoadingViewToContainer()
                self.updateSubviewsTitles()
                self.animateLoadingViewAppearance(withCompletion: completionBlock)
            }
        }
        
        operationShow.addDependency(operationInit)
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperations([operationInit, operationShow], waitUntilFinished: false)
    }
    
    private func animateLoadingViewAppearance(withCompletion completionBlock: ALLVCompletionBlock? = nil) {
        self.updateContentViewAlphaValue(0.0)
        UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
            self.updateContentViewAlphaValue(1.0)
        }) { finished -> Void in
            if finished {
                self.loadingViewProgress = .loaded
                completionBlock?()
            }
        }
    }
    
    // MARK: Hiding loading view
    
    /// Hide loading view with delay.
    ///
    /// - parameter delay: Time interval for delay. Optional. 0 by default
    /// - parameter completionBlock: The closure called when loading view is removed. Optional.
    public func hideLoadingView(withDelay delay: TimeInterval? = nil, completionBlock: ALLVCompletionBlock? = nil) {
        stackView?.isHidden = false
        let delayValue : TimeInterval = delay ?? 0.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delayValue * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.loadingViewProgress = .hiding
            self.animateLoadingViewDisappearance(withCompletion: completionBlock)
        }
    }
    
    private func animateLoadingViewDisappearance(withCompletion completionBlock: ALLVCompletionBlock? = nil) {
        if isUsingBlurEffect {
            self.loadingViewProgress = .hidden
            self.loadingView?.removeFromSuperview()
            completionBlock?()
            self.freeViewData()
        } else {
            UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                self.appearanceView?.alpha = 0.0
            }) { finished -> Void in
                if finished {
                    self.loadingViewProgress = .hidden
                    self.loadingView?.removeFromSuperview()
                    completionBlock?()
                    self.freeViewData()
                }
            }
        }
    }
    
    private func freeViewData() {
        // View is hidden, now free memory
        for subview in loadingViewSubviews() {
            subview.removeFromSuperview()
        }
        self.stackView?.removeFromSuperview()
        self.appearanceView?.removeFromSuperview()
        self.stackView = nil
        self.appearanceView = nil
        self.loadingView = nil
    }
    
    // MARK: Reset to defaults
    
    /// Reset all appearance parameters. For default value check corresponding property.
    public func resetToDefaults() {
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.textColor = UIColor(white: 1.0, alpha: 1.0)
        self.messageFont = UIFont.systemFont(ofSize: 25.0)
        self.blurredBackground = false
        self.animationDuration = 0.5
        self.messageText = "Loading"
        self.cornerRadius = 0.0
        self.windowRatio = 0.4
        self.itemSpacing = 20.0
        //
        self.loadingViewWindowMode = .fullscreen
        self.loadingViewType = .basic
    }
    
    // MARK: Updating subviews data
    
    /// Update loading view progress view value and text view message. If using only text view, use `-updateMessageLabel()`.
    ///
    /// - parameter message: String for UITextView.
    /// - parameter progress: Progress value for UIProgressView.
    public func updateProgressLoadingView(withMessage message: String, forProgress progress: Float) {
        DispatchQueue.main.async {
            self.progress_updateProgressControls(withData: ["message": message, "progress" : progress])
        }
    }
    
    /// Update UITextView and UIProgressView with specified values.
    ///
    /// - parameter data: Dictionary with message string and progress value. Keys: "message", "progress"
    private func progress_updateProgressControls(withData data: NSDictionary) {
        let message = data["message"] as? String ?? ""
        let progress = data["progress"] as? Float ?? 0.0
        
        for view in self.loadingViewSubviews() {
            if let textView = view as? UITextView, textView.responds(to: #selector(setter: UITextView.text)) {
                // Update text
                textView.text = message
            }
            if view.responds(to: #selector(setter: UIProgressView.progress)) {
                (view as! UIProgressView).progress = progress
            }
        }
        
        checkContentSize()
    }
    
    /// Update text view message.
    ///
    /// - parameter message: String for UITextView.
    public func updateMessageLabel(withText message: String) {
        DispatchQueue.main.async {
            self.progress_updateProgressControls(withData: ["message": message])
        }
    }
    
    private func updateSubviewsTitles() {
        let subviews: [UIView] = self.loadingViewSubviews()
        
        switch self.loadingViewType {
        case .message, .messageWithIndicator:
            updateMessageLabel(withText: messageText)
            break
        case .messageWithIndicatorAndCancelButton:
            updateMessageLabel(withText: messageText)
            
            for view in subviews {
                if view is UIButton {
                    (view as! UIButton).setTitle("Cancel", for: UIControlState())
                    (view as! UIButton).addTarget(self, action: #selector(ALLoadingView.cancelButtonTapped(_:)), for: .touchUpInside)
                }
            }
            break
        case .progress:
            updateProgressLoadingView(withMessage: messageText, forProgress: 0.0)
            break
        case .progressWithCancelButton:
            updateProgressLoadingView(withMessage: messageText, forProgress: 0.0)
            
            for view in subviews {
                if view is UIButton {
                    (view as! UIButton).setTitle("Cancel", for: UIControlState())
                    (view as! UIButton).addTarget(self, action: #selector(ALLoadingView.cancelButtonTapped(_:)), for: .touchUpInside)
                }
            }
            break
        default:
            break
        }
    }
    
    //MARK: - Private methods
    //MARK: Initialize view
    private func initializeLoadingView() {
        loadingView = UIView(frame: CGRect.zero)
        loadingView?.backgroundColor = UIColor.clear
        loadingView?.clipsToBounds = true
        
        // Create blank stack view, will configure later
        stackView = UIStackView()
        
        // Set up appearance view (blur, color, such stuff)
        initializeAppearanceView()
    
        // View has been created. Add subviews according to selected type.
        configureStackView()
        createSubviewsForStackView()
    }
    
    private func initializeAppearanceView() {
        guard let loadingView = loadingView, let stackView = stackView else {
            return
        }
        
        if isUsingBlurEffect {
            let lightBlur = UIBlurEffect(style: .dark)
            let lightBlurView = UIVisualEffectView(effect: lightBlur)
            appearanceView = lightBlurView
            
            // Add stack view
            lightBlurView.contentView.addSubview(stackView)
        } else {
            appearanceView = UIView(frame: CGRect.zero)
            appearanceView?.backgroundColor = backgroundColor
            
            // Add stack view
            appearanceView?.addSubview(stackView)
        }
        appearanceView?.layer.cornerRadius = cornerRadius
        appearanceView?.layer.masksToBounds = true
        
        loadingView.addSubview(appearanceView!)
    }
    
    private func configureStackView() {
        guard let stackView = stackView else {
            return
        }
        
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.spacing = itemSpacing
        
        if kALLoadingViewDebugModeKey {
            let backgroundView = UIView(frame: CGRect.zero)
            backgroundView.backgroundColor = UIColor.green
            
            stackView.addSubview(backgroundView)
            stackView.sendSubview(toBack: backgroundView)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
            backgroundView.leftAnchor.constraint(equalTo: stackView.leftAnchor).isActive = true
            backgroundView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1.0).isActive = true
            backgroundView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 1.0).isActive = true
        }
    }
    
    private func attachLoadingViewToContainer() {
        guard let loadingView = loadingView, let appearanceView = appearanceView else {
            return
        }
        let container: UIView
        
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        let viewControllerCurrentlyVisible = rootViewController?.presentedViewController ?? rootViewController
        
        if let viewControllerView = viewControllerCurrentlyVisible?.view {
            container = viewControllerView
        } else {
            container = UIApplication.shared.windows[0]
        }
        
        container.addSubview(loadingView)
        
        
        // Set constraints for loading view (container)
        view_setWholeScreenConstraints(forView: loadingView, inContainer: container)
        
        // Set constraints for appearance view
        if loadingViewWindowMode == .fullscreen {
            view_setWholeScreenConstraints(forView: appearanceView, inContainer: loadingView)
        } else {
            view_setSizeConstraints(forView: appearanceView, inContainer: loadingView)
        }
    }

    private func view_setWholeScreenConstraints(forView subview: UIView, inContainer container: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(item: subview, attribute: .top,
                                               relatedBy: .equal, toItem: container,
                                               attribute: .top, multiplier: 1, constant: 0)
        let bottomContraint = NSLayoutConstraint(item: subview, attribute: .bottom,
                                                 relatedBy: .equal, toItem: container,
                                                 attribute: .bottom, multiplier: 1, constant: 0)
        let trallingConstaint = NSLayoutConstraint(item: subview, attribute: .trailing,
                                                   relatedBy: .equal, toItem: container,
                                                   attribute: .trailing, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: subview, attribute: .leading,
                                                   relatedBy: .equal, toItem: container,
                                                   attribute: .leading, multiplier: 1, constant: 0)
        container.addConstraints([topConstraint, bottomContraint, leadingConstraint, trallingConstaint])
    }
    
    private func view_setSizeConstraints(forView subview: UIView, inContainer container: UIView) {
        let frame = frameForView
        subview.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = NSLayoutConstraint(item: subview, attribute: .height,
                                               relatedBy: .equal, toItem: nil,
                                               attribute: .notAnAttribute, multiplier: 1, constant: frame.size.height)
        let widthContraint = NSLayoutConstraint(item: subview, attribute: .width,
                                                 relatedBy: .equal, toItem: nil,
                                                 attribute: .notAnAttribute, multiplier: 1, constant: frame.size.width)
        let centerXConstaint = NSLayoutConstraint(item: subview, attribute: .centerX,
                                                   relatedBy: .equal, toItem: container,
                                                   attribute: .centerX, multiplier: 1, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: subview, attribute: .centerY,
                                                   relatedBy: .equal, toItem: container,
                                                   attribute: .centerY, multiplier: 1, constant: 0)
        container.addConstraints([heightConstraint, widthContraint, centerYConstraint, centerXConstaint])
    }
    
    private func createSubviewsForStackView() {
        guard let stackView = stackView else {
            return
        }
        let viewTypes = getSubviewsTypes()
        
        // calculate frame for each view
        for viewType in viewTypes {
            let view = initializeView(withType: viewType, andFrame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
            
            stackView.addArrangedSubview(view)

            if view.intrinsicContentSize.width == UIViewNoIntrinsicMetric {
                view.translatesAutoresizingMaskIntoConstraints = false
                view.widthAnchor.constraint(equalToConstant: frameForView.width).isActive = true
            }
        }
        
        self.loadingViewProgress = .viewReady
        
        // Setting up constraints for stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.widthAnchor.constraint(equalTo: (stackView.superview?.widthAnchor)!, multiplier: 1).isActive = true
        stackView.centerXAnchor.constraint(equalTo: (stackView.superview?.centerXAnchor)!).isActive = true
        stackView.centerYAnchor.constraint(equalTo: (stackView.superview?.centerYAnchor)!).isActive = true
        stackView.heightAnchor.constraint(lessThanOrEqualTo: (stackView.superview?.heightAnchor)!, constant: 0.0).isActive = true
    }
    
    private func getSubviewsTypes() -> [ALLVViewType] {
        switch self.loadingViewType {
        case .basic:
            return [.activityIndicator]
        case .message:
            return [.messageTextView]
        case .messageWithIndicator:
            return [.messageTextView, .activityIndicator]
        case .messageWithIndicatorAndCancelButton:
            if self.loadingViewWindowMode == ALLVWindowMode.windowed {
                return [.messageTextView, .activityIndicator, .cancelButton]
            } else {
                return [.messageTextView, .activityIndicator, .cancelButton]
            }
        case .progress:
            return [.messageTextView, .progressBar]
        case .progressWithCancelButton:
            return [.messageTextView, .progressBar, .cancelButton]
        }
    }
    
    //MARK: Content size checker
    private func checkContentSize() {
        guard let stackView = stackView else {
            return
        }
        
        var contentSizeHeight : CGFloat = 0
        stackView.arrangedSubviews.forEach {
            contentSizeHeight += $0.elementHeightAtStackView()
        }
        contentSizeHeight += CGFloat(stackView.arrangedSubviews.count - 1) * itemSpacing
        
        let stackViewSizeHeight = stackView.elementHeightAtStackView()
        if stackViewSizeHeight == 0 {
            return
        }
        
        assert(stackViewSizeHeight >= contentSizeHeight, "ALLoadingView Presentation Error. Required content size (\(contentSizeHeight)) is bigger than available space (\(stackViewSizeHeight)). Check 'itemSpacing', 'windowRatio' properties description or label's content")
    }
    
    //MARK: Loading view accessors & methods
    private func loadingViewSubviews() -> [UIView] {
        guard let stackView = stackView else {
            return []
        }
        return stackView.arrangedSubviews
    }
    
    private func updateContentViewAlphaValue(_ alpha: CGFloat) {
        if isUsingBlurEffect {
            if let asVisualEffectView = appearanceView as? UIVisualEffectView {
                asVisualEffectView.contentView.alpha = alpha
            }
        } else {
            appearanceView?.alpha = alpha
        }
    }
    
    //MARK: Initializing subviews
    private func initializeView(withType type: ALLVViewType, andFrame frame: CGRect) -> UIView {
        switch type {
        case .messageTextView:
            return view_messageTextView()
        case .activityIndicator:
            return view_activityIndicator()
        case .cancelButton:
            return view_cancelButton(frame)
        case .blankSpace:
            return UIView(frame: frame)
        case .progressBar:
            return view_standardProgressBar()
        }
    }
    
    private func view_activityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    private func view_messageTextView() -> UITextView {
        let textView = UITextView(frame: CGRect.zero)
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.textColor = textColor
        textView.font = messageFont
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        
        return textView
    }
    
    private func view_cancelButton(_ frame: CGRect) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = frame
        button.setTitleColor(UIColor.white, for: UIControlState.normal)
        button.backgroundColor = UIColor.clear
        return button
    }
    
    private func view_standardProgressBar() -> UIProgressView {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        
        return progressView
    }
    
    // MARK: Subviews actions
    public func cancelButtonTapped(_ sender: AnyObject?) {
        if let _ = sender as? UIButton {
            cancelCallback?()
        }
    }
    
    public func coverContent() {
        stackView?.isHidden = true
    }
}

extension UIView {
    func elementHeightAtStackView() -> CGFloat {
        if self.constraints.count > 0 {
            if let heightConstraint = self.constraints.filter({ $0.firstAttribute == .height && $0.constant != 0
            }).first {
                return heightConstraint.constant
            }
        }
        if self.intrinsicContentSize.height > 0 {
            return self.intrinsicContentSize.height
        }
        return self.frame.height
    }
}
