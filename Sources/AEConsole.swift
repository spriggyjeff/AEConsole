//
// AEConsole.swift
//
// Copyright (c) 2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import AELog
import UIKit

/// Displays log generated by `aelog` in Console UI overlay on top of your app.
public class AEConsole: AELogDelegate {
    
    // MARK: - Outlets
    
    private var consoleView: AEConsoleView!
    
    // MARK: - Properties
    
    private static let sharedInstance = AEConsole()
    private let settings = AEConsoleSettings()
    private var appDelegate: UIApplicationDelegate? {
        didSet {
            if let delegate = appDelegate {
                configureConsoleViewViaAppDelegate(delegate)
            }
        }
    }
    
    private func configureConsoleViewViaAppDelegate(delegate: UIApplicationDelegate) {
        guard let _window = delegate.window, window = _window else { return }
        let console = AEConsoleView()
        console.frame = window.bounds
        console.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        console.hidden = !settings.consoleAutoStart
        window.addSubview(console)
        consoleView = console
    }
    
    // MARK: - API
    
    /// Enable Console UI by calling this method in your AppDelegate's `didFinishLaunchingWithOptions:`
    public class func launchWithAppDelegate(delegate: UIApplicationDelegate) {
        AELog.launchWithDelegate(sharedInstance)
        sharedInstance.appDelegate = delegate
    }
    
    /// Current state of Console UI visibility
    public class var hidden: Bool {
        return sharedInstance.consoleView.hidden
    }
    
    /// Toggle Console UI
    public class func toggle() {
        if sharedInstance.consoleView.hidden {
            sharedInstance.activateConsoleUI()
        }
        sharedInstance.consoleView.toggleUI()
    }
    
    // MARK: - Init
    
    private init() {
        let center = NSNotificationCenter.defaultCenter()
        let notification = UIApplicationDidBecomeActiveNotification
        center.addObserver(self, selector: #selector(activateConsoleUI), name: notification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc private func activateConsoleUI() {
        guard let
            delegate = appDelegate,
            _window = delegate.window, window = _window
        else { return }

        window.bringSubviewToFront(consoleView)
        if settings.shakeGestureEnabled {
            consoleView.becomeFirstResponder()
        }
    }
    
    // MARK: - AELogDelegate
    
    /**
        Forwards latest log line from `aelog` to Console UI.

        - NOTE: If `AEConsole` setting "Enabled" is set to "NO" then it does nothing.

        - parameter logLine: Log line which will be added to Console UI.
    */
    public func didLog(logLine: AELogLine) {
        if settings.consoleEnabled {
            consoleView.addLogLine(logLine)
            activateConsoleUI()
        }
    }
    
}

// MARK: - AEConsoleSettings

/**
    Helper for accessing settings from the external file (same file used by `AELog`).

    Create `AELog.plist` dictionary file and add it to your target.
    Add `Console` dictionary inside it and there you can manage all console settings.

    There is `Key` struct which contains possible keys for all settings.
*/
public class AEConsoleSettings: AELogSettings {
    
    // MARK: Constants
    
    /// Setting keys which can be used in `Console` dictionary inside `AELog.plist`.
    public struct Key {
        public static let ConsoleSettings = "Console"
        
        public struct Console {
            /// Boolean - Console UI enabled flag (defaults to `YES`)
            public static let Enabled = "Enabled"
            
            /// Boolean - Console UI visible on app start flag (defaults to `NO`)
            public static let AutoStart = "AutoStart"
            
            /// Boolean - Shake gesture enabled flag (defaults to `YES`)
            public static let ShakeGesture = "ShakeGesture"
            
            /// String - Hex string for Console background color (defaults to 000000)
            public static let BackColor = "BackColor"
            
            /// String - Hex string for Console text color (defaults to FFFFFF)
            public static let TextColor = "TextColor"
            
            /// Number - Console UI font size (defaults to 12)
            public static let FontSize = "FontSize"
            
            /// Number - Console UI row height (defaults to 14)
            public static let RowHeight = "RowHeight"
            
            /// Number - Console UI opacity (defaults to 0.7)
            public static let Opacity = "Opacity"
        }
    }
    
    private struct Default {
        private static let Enabled = true
        private static let AutoStart = false
        private static let ShakeGesture = true
        private static let BackColor = UIColor.blackColor()
        private static let TextColor = UIColor.whiteColor()
        private static let FontSize: CGFloat = 12.0
        private static let RowHeight: CGFloat = 14.0
        private static let Opacity: CGFloat = 0.7
    }
    
    // MARK: Properties
    
    private lazy var textColorWithOpacity: UIColor = { [unowned self] in
        self.consoleTextColor.colorWithAlphaComponent(Default.Opacity)
    }()
    
    private lazy var consoleSettings: [String : AnyObject]? = { [unowned self] in
        guard let
            settings = self.plist,
            console = settings[Key.ConsoleSettings] as? [String : AnyObject]
        else { return nil }
        return console
    }()
    
    // MARK: Settings
    
    private lazy var consoleFont: UIFont = {
        return UIFont.monospacedDigitSystemFontOfSize(self.consoleFontSize, weight: UIFontWeightRegular)
    }()
    
    private lazy var consoleEnabled: Bool = { [unowned self] in
        guard let enabled = self.boolForKey(Key.Console.Enabled)
        else { return Default.Enabled }
        return enabled
    }()
    
    private lazy var consoleAutoStart: Bool = { [unowned self] in
        guard let autoStart = self.boolForKey(Key.Console.AutoStart)
        else { return Default.AutoStart }
        return autoStart
    }()
    
    private lazy var shakeGestureEnabled: Bool = { [unowned self] in
        guard let shake = self.boolForKey(Key.Console.ShakeGesture)
        else { return Default.ShakeGesture }
        return shake
    }()
    
    private lazy var consoleBackColor: UIColor = { [unowned self] in
        guard let color = self.colorForKey(Key.Console.BackColor)
        else { return Default.BackColor }
        return color
    }()
    
    private lazy var consoleTextColor: UIColor = { [unowned self] in
        guard let color = self.colorForKey(Key.Console.TextColor)
        else { return Default.TextColor }
        return color
    }()
    
    private lazy var consoleFontSize: CGFloat = { [unowned self] in
        guard let fontSize = self.numberForKey(Key.Console.FontSize)
        else { return Default.FontSize }
        return fontSize
    }()
    
    private lazy var consoleRowHeight: CGFloat = { [unowned self] in
        guard let rowHeight = self.numberForKey(Key.Console.RowHeight)
        else { return Default.RowHeight }
        return rowHeight
    }()
    
    private lazy var consoleOpacity: CGFloat = { [unowned self] in
        guard let opacity = self.numberForKey(Key.Console.Opacity)
        else { return Default.Opacity }
        return opacity
    }()
    
    // MARK: Helpers
    
    private func boolForKey(key: String) -> Bool? {
        guard let
            settings = consoleSettings,
            bool = settings[key] as? Bool
        else { return nil }
        return bool
    }
    
    private func numberForKey(key: String) -> CGFloat? {
        guard let
            settings = consoleSettings,
            number = settings[key] as? CGFloat
        else { return nil }
        return number
    }
    
    private func colorForKey(key: String) -> UIColor? {
        guard let
            settings = consoleSettings,
            hex = settings[key] as? String
        else { return nil }
        let color = colorFromHexString(hex)
        return color
    }
    
    private func colorFromHexString(hex: String) -> UIColor? {
        let scanner = NSScanner(string: hex)
        var hexValue: UInt32 = 0
        if scanner.scanHexInt(&hexValue) {
            let red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            let blue  = CGFloat((hexValue & 0x0000FF)) / 255.0
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return color
        } else { return nil }
    }
    
}

// MARK: - AEConsoleView

class AEConsoleView: UIView, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    // MARK: Constants
    
    private struct Layout {
        static let FilterHeight: CGFloat = 60
        static let FilterExpandedTop: CGFloat = 0
        static let FilterCollapsedTop: CGFloat = -Layout.FilterHeight
        
        static let MenuWidth: CGFloat = 300
        static let MenuHeight: CGFloat = 50
        static let MenuExpandedLeading: CGFloat = -Layout.MenuWidth
        static let MenuCollapsedLeading: CGFloat = -75
        
        static let MagicNumber: CGFloat = 10
    }
    
    // MARK: Outlets
    
    private let tableView = UITableView()
    
    private let filterView = UIView()
    private let filterStack = UIStackView()
    private var filterViewTop: NSLayoutConstraint!
    
    private let exportLogButton = UIButton()
    private let linesCountStack = UIStackView()
    private let linesTotalLabel = UILabel()
    private let linesFilteredLabel = UILabel()
    private let textField = UITextField()
    private let clearFilterButton = UIButton()
    
    private let menuView = UIView()
    private let menuStack = UIStackView()
    private var menuViewLeading: NSLayoutConstraint!
    
    private let toggleToolbarButton = UIButton()
    private let forwardTouchesButton = UIButton()
    private let autoFollowButton = UIButton()
    private let clearLogButton = UIButton()
    
    private let updateOpacityGesture = UIPanGestureRecognizer()
    private let hideConsoleGesture = UITapGestureRecognizer()
    
    // MARK: API
    
    func addLogLine(logLine: AELogLine) {
        let calculatedLineWidth = widthForLine(logLine.description)
        if calculatedLineWidth > maxLineWidth {
            maxLineWidth = calculatedLineWidth
        }
        
        if filterActive {
            guard let filter = filterText else { return }
            if logLine.description.containsString(filter) {
                filteredLines.append(logLine)
            }
        }
        
        lines.append(logLine)
    }
    
    func toggleUI() {
        textField.resignFirstResponder()
        UIView.transitionWithView(self, duration: 0.3, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.hidden = !self.hidden
        }, completion: nil)
    }
    
    // MARK: Properties
    
    private let settings = AEConsole.sharedInstance.settings
    
    private var maxLineWidth: CGFloat = 0.0
    private var currentOffsetX = -Layout.MagicNumber
    
    private var toolbarActive = false {
        didSet {
            currentTopInset = toolbarActive ? topInsetLarge : topInsetSmall
        }
    }
    
    private var currentTopInset = Layout.MagicNumber
    private var topInsetSmall = Layout.MagicNumber
    private var topInsetLarge = Layout.MagicNumber + Layout.FilterHeight
    
    private var lines = [AELogLine]() {
        didSet {
            updateUI()
        }
    }
    
    private var filteredLines = [AELogLine]()
    
    private var filterText: String? {
        didSet {
            filterActive = !isEmpty(filterText)
        }
    }
    
    private var filterActive = false {
        didSet {
            updateFilter()
            updateUI()
        }
    }
    
    private func updateFilter() {
        if filterActive {
            guard let filter = filterText else { return }
            aelog("Filter Lines [\(filterActive)] - <\(filter)>")
            let filtered = lines.filter({ $0.description.localizedCaseInsensitiveContainsString(filter) })
            filteredLines = filtered
        } else {
            aelog("Filter Lines [\(filterActive)]")
            filteredLines.removeAll()
        }
    }
    
    private var opacity: CGFloat = 1.0 {
        didSet {
            configureColorsWithOpacity(opacity)
        }
    }
    
    // MARK: Helpers
    
    private func updateUI() {
        tableView.reloadData()
        
        updateLinesCountLabels()
        updateContentLayout()
        
        if autoFollowButton.selected {
            scrollToBottom()
        }
    }
    
    private func updateLinesCountLabels() {
        linesTotalLabel.text = "□ \(lines.count)"
        let filteredCount = filterActive ? filteredLines.count : 0
        linesFilteredLabel.text = "■ \(filteredCount)"
    }
    
    private func updateContentLayout() {
        let maxWidth = max(maxLineWidth, bounds.width)
        
        let newFrame = CGRect(x: 0.0, y: 0.0, width: maxWidth, height: bounds.height)
        tableView.frame = newFrame
        
        UIView.animateWithDuration(0.3) { [unowned self] () -> Void in
            let inset = Layout.MagicNumber
            let newInset = UIEdgeInsets(top: self.currentTopInset, left: inset, bottom: inset, right: maxWidth)
            self.tableView.contentInset = newInset
        }
        
        updateContentOffset()
    }
    
    private func updateContentOffset() {
        if toolbarActive {
            if tableView.contentOffset.y == -topInsetSmall {
                let offset = CGPoint(x: tableView.contentOffset.x, y: -topInsetLarge)
                tableView.setContentOffset(offset, animated: true)
            }
        } else {
            if tableView.contentOffset.y == -topInsetLarge {
                let offset = CGPoint(x: tableView.contentOffset.x, y: -topInsetSmall)
                tableView.setContentOffset(offset, animated: true)
            }
        }
        tableView.flashScrollIndicators()
    }
    
    private func scrollToBottom() {
        let diff = tableView.contentSize.height - tableView.bounds.size.height
        if diff > 0 {
            let offsetY = diff + Layout.MagicNumber
            let bottomOffset = CGPoint(x: currentOffsetX, y: offsetY)
            tableView.setContentOffset(bottomOffset, animated: false)
        }
    }
    
    private func configureColorsWithOpacity(opacity: CGFloat) {
        tableView.backgroundColor = settings.consoleBackColor.colorWithAlphaComponent(opacity)
        
        let textOpacity = max(0.3, opacity * 1.1)
        settings.textColorWithOpacity = settings.consoleTextColor.colorWithAlphaComponent(textOpacity)
        
        let toolbarOpacity = min(0.7, opacity * 1.5)
        filterView.backgroundColor = settings.consoleBackColor.colorWithAlphaComponent(toolbarOpacity)
        menuView.backgroundColor = settings.consoleBackColor.colorWithAlphaComponent(toolbarOpacity)
        
        let borderOpacity = toolbarOpacity / 2
        filterView.layer.borderColor = settings.consoleBackColor.colorWithAlphaComponent(borderOpacity).CGColor
        filterView.layer.borderWidth = 1.0
        menuView.layer.borderColor = settings.consoleBackColor.colorWithAlphaComponent(borderOpacity).CGColor
        menuView.layer.borderWidth = 1.0
        
        if !lines.isEmpty {
            // refresh text color
            tableView.reloadData()
        }
    }
    
    // MARK: Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        configureUI()
        opacity = settings.consoleOpacity
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = filterActive ? filteredLines : lines
        return rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(AEConsoleCell.identifier) as! AEConsoleCell
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let rows = filterActive ? filteredLines : lines
        let logLine = rows[indexPath.row]
        cell.textLabel?.text = logLine.description
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if !isEmpty(textField.text) {
            filterText = textField.text
        }
        return true
    }
    
    // MARK: Actions
    
    func didTapToggleToolbarButton(sender: UIButton) {
        toggleToolbar()
    }
    
    func didTapForwardTouchesButton(sender: UIButton) {
        forwardTouchesButton.selected = !forwardTouchesButton.selected
        aelog("Forward Touches [\(forwardTouchesButton.selected)]")
    }
    
    func didTapAutoFollowButton(sender: UIButton) {
        autoFollowButton.selected = !autoFollowButton.selected
        aelog("Auto Follow [\(autoFollowButton.selected)]")
    }
    
    func didTapClearLogButton(sender: UIButton) {
        clearLog()
    }
    
    func didTapExportButton(sender: UIButton) {
        exportAllLogLines()
    }
    
    func didTapFilterClearButton(sender: UIButton) {
        textField.resignFirstResponder()
        if !isEmpty(textField.text) {
            filterText = nil
        }
        textField.text = nil
    }
    
    func didRecognizeUpdateOpacityGesture(sender: UIPanGestureRecognizer) {
        if sender.state == .Ended {
            let xTranslation = sender.translationInView(menuView).x
            if abs(xTranslation) > (3 * Layout.MagicNumber) {
                let location = sender.locationInView(menuView)
                let opacity = opacityForLocation(location)
                self.opacity = opacity
            }
        }
    }
    
    func didRecognizeHideConsoleGesture(sender: UITapGestureRecognizer) {
        toggleUI()
    }
    
    // MARK: Helpers
    
    private func widthForLine(line: String) -> CGFloat {
        let maxSize = CGSize(width: CGFloat.max, height: settings.consoleRowHeight)
        let options = NSStringDrawingOptions.UsesLineFragmentOrigin
        let attributes = [NSFontAttributeName : settings.consoleFont]
        let nsLine = line as NSString
        let size = nsLine.boundingRectWithSize(maxSize, options: options, attributes: attributes, context: nil)
        let width = size.width
        return width
    }
    
    private func opacityForLocation(location: CGPoint) -> CGFloat {
        let calculatedOpacity = ((location.x * 1.0) / 300)
        let minOpacity = max(0.1, calculatedOpacity)
        let maxOpacity = min(0.9, minOpacity)
        return maxOpacity
    }
    
    private func isEmpty(text: String?) -> Bool {
        guard let text = text else { return true }
        let characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let isTextEmpty = text.stringByTrimmingCharactersInSet(characterSet).isEmpty
        return isTextEmpty
    }
    
    private func toggleToolbar() {
        filterViewTop.constant = toolbarActive ? Layout.FilterCollapsedTop : Layout.FilterExpandedTop
        menuViewLeading.constant = toolbarActive ? Layout.MenuCollapsedLeading : Layout.MenuExpandedLeading
        let alpha: CGFloat = toolbarActive ? 0.3 : 1.0
        
        UIView.animateWithDuration(0.3) {
            self.filterView.alpha = alpha
            self.menuView.alpha = alpha
            self.filterView.layoutIfNeeded()
            self.menuView.layoutIfNeeded()
        }
        
        if toolbarActive {
            textField.resignFirstResponder()
        }
        
        toolbarActive = !toolbarActive
    }
    
    private func clearLog() {
        lines.removeAll()
        filteredLines.removeAll()
        updateUI()
    }
    
    private func exportAllLogLines() {
        let stringLines = lines.map({ $0.description })
        let log = stringLines.joinWithSeparator("\n")
        
        if isEmpty(log) {
            aelog("Log is empty, nothing to export here.")
        } else {
            let filename = "\(NSDate().timeIntervalSince1970).aelog"
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let documentsURL = NSURL(fileURLWithPath: documentsPath)
            let fileURL = documentsURL.URLByAppendingPathComponent(filename)
            
            do {
                try log.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding)
                aelog("Log is exported to path: \(fileURL)")
            } catch {
                aelog(error)
            }
        }
    }
    
    // MARK: UI
    
    private func configureUI() {
        configureOutlets()
        configureLayout()
    }
    
    private func configureOutlets() {
        configureTableView()
        configureFilterView()
        configureMenuView()
        configureGestures()
    }
    
    private func configureTableView() {
        tableView.rowHeight = settings.consoleRowHeight
        tableView.allowsSelection = false
        tableView.separatorStyle = .None
        
        tableView.registerClass(AEConsoleCell.self, forCellReuseIdentifier: AEConsoleCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureFilterView() {
        configureFilterStack()
        configureFilterLinesCount()
        configureFilterTextField()
        configureFilterButtons()
    }
    
    private func configureFilterStack() {
        filterView.alpha = 0.3
        filterStack.axis = .Horizontal
        filterStack.alignment = .Fill
        filterStack.distribution = .Fill
        
        let stackInsets = UIEdgeInsets(top: Layout.MagicNumber, left: 0, bottom: 0, right: 0)
        filterStack.layoutMargins = stackInsets
        filterStack.layoutMarginsRelativeArrangement = true
    }
    
    private func configureFilterLinesCount() {
        linesCountStack.axis = .Vertical
        linesCountStack.alignment = .Fill
        linesCountStack.distribution = .FillEqually
        let stackInsets = UIEdgeInsets(top: Layout.MagicNumber, left: 0, bottom: Layout.MagicNumber, right: 0)
        linesCountStack.layoutMargins = stackInsets
        linesCountStack.layoutMarginsRelativeArrangement = true
        
        linesTotalLabel.font = settings.consoleFont
        linesTotalLabel.textColor = settings.consoleTextColor
        linesTotalLabel.textAlignment = .Left
        
        linesFilteredLabel.font = settings.consoleFont
        linesFilteredLabel.textColor = settings.consoleTextColor
        linesFilteredLabel.textAlignment = .Left
    }
    
    private func configureFilterTextField() {
        let textColor = settings.consoleTextColor
        textField.delegate = self
        textField.autocapitalizationType = .None
        textField.tintColor = textColor
        textField.font = settings.consoleFont.fontWithSize(14)
        textField.textColor = textColor
        let attributes = [NSForegroundColorAttributeName : textColor.colorWithAlphaComponent(0.5)]
        let placeholderText = NSAttributedString(string: "Type here...", attributes: attributes)
        textField.attributedPlaceholder = placeholderText
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(Layout.MagicNumber, 0, 0)
    }
    
    private func configureFilterButtons() {
        exportLogButton.setTitle("🌙", forState: .Normal)
        exportLogButton.addTarget(self, action: #selector(didTapExportButton(_:)), forControlEvents: .TouchUpInside)
        
        clearFilterButton.setTitle("🔥", forState: .Normal)
        clearFilterButton.addTarget(self, action: #selector(didTapFilterClearButton(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func configureMenuView() {
        configureMenuStack()
        configureMenuButtons()
    }
    
    private func configureMenuStack() {
        menuView.alpha = 0.3
        menuView.layer.cornerRadius = Layout.MagicNumber
        
        menuStack.axis = .Horizontal
        menuStack.alignment = .Fill
        menuStack.distribution = .FillEqually
    }
    
    private func configureMenuButtons() {
        toggleToolbarButton.setTitle("☀️", forState: .Normal)
        forwardTouchesButton.setTitle("⚡️", forState: .Normal)
        forwardTouchesButton.setTitle("✨", forState: .Selected)
        autoFollowButton.setTitle("🌟", forState: .Normal)
        autoFollowButton.setTitle("💫", forState: .Selected)
        clearLogButton.setTitle("🔥", forState: .Normal)
        
        autoFollowButton.selected = true
        
        toggleToolbarButton.addTarget(self, action: #selector(didTapToggleToolbarButton(_:)), forControlEvents: .TouchUpInside)
        forwardTouchesButton.addTarget(self, action: #selector(didTapForwardTouchesButton(_:)), forControlEvents: .TouchUpInside)
        autoFollowButton.addTarget(self, action: #selector(didTapAutoFollowButton(_:)), forControlEvents: .TouchUpInside)
        clearLogButton.addTarget(self, action: #selector(didTapClearLogButton(_:)), forControlEvents: .TouchUpInside)
    }
    
    private func configureGestures() {
        configureUpdateOpacityGesture()
        configureHideConsoleGesture()
    }
    
    private func configureUpdateOpacityGesture() {
        updateOpacityGesture.addTarget(self, action: #selector(didRecognizeUpdateOpacityGesture(_:)))
        menuView.addGestureRecognizer(updateOpacityGesture)
    }
    
    private func configureHideConsoleGesture() {
        hideConsoleGesture.numberOfTouchesRequired = 2
        hideConsoleGesture.numberOfTapsRequired = 2
        hideConsoleGesture.addTarget(self, action: #selector(didRecognizeHideConsoleGesture(_:)))
        addGestureRecognizer(hideConsoleGesture)
    }
    
    // MARK: Layout
    
    private func configureLayout() {
        configureHierarchy()
        configureViewsForLayout()
        configureConstraints()
    }
    
    private func configureHierarchy() {
        addSubview(tableView)
        
        filterStack.addArrangedSubview(exportLogButton)
        
        linesCountStack.addArrangedSubview(linesTotalLabel)
        linesCountStack.addArrangedSubview(linesFilteredLabel)
        filterStack.addArrangedSubview(linesCountStack)
        
        filterStack.addArrangedSubview(textField)
        filterStack.addArrangedSubview(clearFilterButton)
        
        filterView.addSubview(filterStack)
        addSubview(filterView)
        
        menuStack.addArrangedSubview(toggleToolbarButton)
        menuStack.addArrangedSubview(forwardTouchesButton)
        menuStack.addArrangedSubview(autoFollowButton)
        menuStack.addArrangedSubview(clearLogButton)
        menuView.addSubview(menuStack)
        addSubview(menuView)
    }
    
    private func configureViewsForLayout() {
        filterView.translatesAutoresizingMaskIntoConstraints = false
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuStack.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureConstraints() {
        configureFilterViewConstraints()
        configureFilterStackConstraints()
        configureFilterStackSubviewConstraints()
        
        configureMenuViewConstraints()
        configureMenuStackConstraints()
    }
    
    private func configureFilterViewConstraints() {
        let leading = filterView.leadingAnchor.constraintEqualToAnchor(leadingAnchor)
        let trailing = filterView.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
        let height = filterView.heightAnchor.constraintEqualToConstant(Layout.FilterHeight)
        filterViewTop = filterView.topAnchor.constraintEqualToAnchor(topAnchor, constant: Layout.FilterCollapsedTop)
        NSLayoutConstraint.activateConstraints([leading, trailing, height, filterViewTop])
    }
    
    private func configureFilterStackConstraints() {
        let leading = filterStack.leadingAnchor.constraintEqualToAnchor(filterView.leadingAnchor)
        let trailing = filterStack.trailingAnchor.constraintEqualToAnchor(filterView.trailingAnchor)
        let top = filterStack.topAnchor.constraintEqualToAnchor(filterView.topAnchor)
        let bottom = filterStack.bottomAnchor.constraintEqualToAnchor(filterView.bottomAnchor)
        NSLayoutConstraint.activateConstraints([leading, trailing, top, bottom])
    }
    
    private func configureFilterStackSubviewConstraints() {
        let exportButtonWidth = exportLogButton.widthAnchor.constraintEqualToConstant(75)
        let linesCountWidth = linesCountStack.widthAnchor.constraintGreaterThanOrEqualToConstant(50)
        let clearFilterButtonWidth = clearFilterButton.widthAnchor.constraintEqualToConstant(75)
        NSLayoutConstraint.activateConstraints([exportButtonWidth, linesCountWidth, clearFilterButtonWidth])
    }
    
    private func configureMenuViewConstraints() {
        let width = menuView.widthAnchor.constraintEqualToConstant(Layout.MenuWidth + Layout.MagicNumber)
        let height = menuView.heightAnchor.constraintEqualToConstant(Layout.MenuHeight)
        let centerY = menuView.centerYAnchor.constraintEqualToAnchor(centerYAnchor)
        menuViewLeading = menuView.leadingAnchor.constraintEqualToAnchor(trailingAnchor, constant: Layout.MenuCollapsedLeading)
        NSLayoutConstraint.activateConstraints([width, height, centerY, menuViewLeading])
    }
    
    private func configureMenuStackConstraints() {
        let leading = menuStack.leadingAnchor.constraintEqualToAnchor(menuView.leadingAnchor)
        let trailing = menuStack.trailingAnchor.constraintEqualToAnchor(menuView.trailingAnchor, constant: -Layout.MagicNumber)
        let top = menuStack.topAnchor.constraintEqualToAnchor(menuView.topAnchor)
        let bottom = menuStack.bottomAnchor.constraintEqualToAnchor(menuView.bottomAnchor)
        NSLayoutConstraint.activateConstraints([leading, trailing, top, bottom])
    }
    
    // MARK: Override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentLayout()
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, withEvent: event)
        
        let filter = hitView?.superview == filterStack
        let menu = hitView?.superview == menuStack
        if !filter && !menu && forwardTouchesButton.selected {
            return nil
        }
        
        return hitView
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            if settings.shakeGestureEnabled {
                toggleUI()
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            currentOffsetX = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentOffsetX = scrollView.contentOffset.x
    }
    
}

// MARK: - AEConsoleCell

private class AEConsoleCell: UITableViewCell {
    
    // MARK: Constants
    
    static let identifier = "AEConsoleCell"
    
    // MARK: Init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = UIColor.clearColor()
        guard let label = textLabel else { return }
        label.font = AEConsole.sharedInstance.settings.consoleFont
        label.textColor = AEConsole.sharedInstance.settings.textColorWithOpacity
        label.numberOfLines = 1
        label.textAlignment = .Left
    }
    
    // MARK: Override
    
    private override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.textColor = AEConsole.sharedInstance.settings.textColorWithOpacity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = bounds
    }
    
}