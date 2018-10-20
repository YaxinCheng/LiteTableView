//
//  LiteTableView.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

/**
 A faster and simpler table view for macOS
 
 ## Features:
 1. Similar API like UITableView on iOS
 2. Customizable reuse threshold to save memories
 3. StackView based keyboard interactions
 4. Easier to register keyboard callbacks
 */
open class LiteTableView: NSStackView {
  // MARK: - Parameters
  @IBOutlet public weak var liteDelegate: LiteTableDelegate?
  @IBOutlet public weak var liteDataSource: LiteTableDataSource?
  /**
   Stores all the visible cells
  */
  private var displayDeque: Deque<LiteTableCell> = []
  /**
   Stores all the registered nibs with cells
  */
  private var registeredNibs: [NSUserInterfaceItemIdentifier: NSNib] = [:]
  /**
   Stores all the registered cell classes
  */
  private var registeredClasses: [NSUserInterfaceItemIdentifier: LiteTableCell.Type] = [:]
  /**
   Stores all the cells that can be reused
  */
  private var reuseQueues: [NSUserInterfaceItemIdentifier: Deque<LiteTableCell>] = [:]
  /**
   The iterator for displayDeque. Used to move the cursor up and down
   */
  private lazy var currentCell: Deque<LiteTableCell>.Iterator = {
    return displayDeque.makeIterator()
  }()
  /**
   A flag indicating if the `currentCell` needs to be reset.
   
   This is used to defer the reset process, and reduce the time consumption during reloading
  */
  private var resetCurrFlag: Bool = false
  /**
   This indicates the highlighted cell index
  */
  private var currentIndex: Int = -1
  /**
   A keyboard monitor
  */
  private var keyboardMonitor: Any?
  
  /**
   The highlighted cell.
   
   It can be `nil` when no cell is highlighted
  */
  open private(set) var highlightedCell: LiteTableCell? {
    willSet {// before set
      if highlightedCell?.highlighted == true {
        // unhighlight the highlighted cell
        highlightedCell?.highlightToggle()
      }
    } didSet {
      // after set
      if highlightedCell?.highlighted == false {
        // highlight the unhighlighted cell
        highlightedCell?.highlightToggle()
      }
    }
  }
  /**
   All the keycodes that needs to monitor
   
   For all keycodes stored here, the delegate function will be called when it is pressed
  */
  open var allowedKeyCodes: Set<UInt16> = [125, 126]
  /**
   All the visible cells
  */
  open var visibleCells: [LiteTableCell] {
    return Array(displayDeque)
  }
  
  // MARK: - Destructor & Constructor
  deinit {
    guard keyboardMonitor != nil else { return }
    NSEvent.removeMonitor(keyboardMonitor!)
    keyboardMonitor = nil
  }
  
  /**
   Constructor called when building from the storyboard
  */
  public required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    translatesAutoresizingMaskIntoConstraints = false
    setUp()
  }
  
  /**
   Constructor called by code
   
   - parameter frameRect: the frame for this tableView
  */
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    translatesAutoresizingMaskIntoConstraints = false
    setUp()
  }
  
  // MARK: - Setup and reset
  /**
   Setup the basic view for the tableView
  */
  private func setUp() {
    distribution = .fill
    spacing = 0
    orientation = .vertical
    alignment = .centerX
    edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
      self?.keyDown(with: $0)
      return $0
    }
  }
  
  /**
   Reset the highlight condition
  */
  private func reset() {
    currentIndex = -1
    highlightedCell = nil
    currentCell = displayDeque.makeIterator()
  }
  
  // MARK: - Open functions
  /**
   When reload function is called, it reloads all cells to the tableView
  */
  open func reload() {
    if displayDeque.count > 0 {
      for cell in displayDeque {
        reuseQueues[cell.identifier!]?.appendFirst(cell)
      }
      displayDeque.removeAll()
      subviews.removeAll()
    }
    reset()
    let threshold = liteDataSource?.cellReuseThreshold(self) ?? 0
    let itemCount = liteDataSource?.numberOfCells(self) ?? 0
    let displayCount = min(threshold, itemCount)
    for index in 0 ..< displayCount {
      guard let cell = liteDataSource?.prepareCell(self, at: index) else { break }
      displayDeque.appendLast(cell)
      addView(cell.view, in: .top)
    }
    resetCurrFlag = true// After adding all cells, make thie flag true to reload iterator later
  }
  
  /**
   Register nib with LiteTableCell in it
   
   - parameter nib: the nib that contains a designed LiteTableCell
   - parameter identifier: the identifier to stored and load the nib
  */
  open func register(nib: NSNib, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
    registeredNibs[identifier] = nib
  }
  
  /**
   Register LiteTableCell class
   
   - parameter class: LiteTableCell class or its subclass
   - parameter identifier: the identifier to stored and load the nib
  */
  open func register(class: LiteTableCell.Type, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
    registeredClasses[identifier] = `class`
  }
  
  open override func keyDown(with event: NSEvent) {
    if resetCurrFlag == true {
      currentCell = displayDeque.makeIterator()
      resetCurrFlag = false
    }
    if event.keyCode == 125 {
      moveDown()
      liteDelegate?.keyPressed?(event)
    } else if event.keyCode == 126 {
      moveUp()
      liteDelegate?.keyPressed?(event)
    } else if allowedKeyCodes.contains(event.keyCode) {
      liteDelegate?.keyPressed?(event)
    } else {
      super.keyUp(with: event)
    }
  }
  
  open override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if allowedKeyCodes.contains(event.keyCode) { return true }
    else { return super.performKeyEquivalent(with: event) }
  }
  
  /**
   This function creates/reuses a LiteTableCell with given identifier
   
   - parameter identifier: the identifier, which is registered before, is used to load the registered class or nib
   - returns: a newly created or an existing reusable cell
  */
  open func dequeueCell(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> LiteTableCell {
    if reuseQueues[identifier] == nil { reuseQueues[identifier] = Deque<LiteTableCell>() }
    if reuseQueues[identifier]!.isEmpty {
      let cell: LiteTableCell
      if let nib = registeredNibs[identifier] {
        cell = loadCell(fromNib: nib)
      } else if let `class` = registeredClasses[identifier] {
        cell = `class`.init()
      } else { fatalError("Unregistered identifier") }
      NSLayoutConstraint.activate([
        cell.view.widthAnchor.constraint(equalToConstant: bounds.width),
        cell.view.heightAnchor.constraint(equalToConstant: liteDataSource?.cellHeight(self) ?? 0)
        ])
      cell.prepareForReuse()
      return cell
    } else {
      return reuseQueues[identifier]!.removeFirst()!
    }
  }
  
  /**
   Load cell from given nib
   - parameter nib: a given nib with LiteTableCell in it
   - returns: the loaded LiteTableCell from the nib
  */
  private func loadCell(fromNib nib: NSNib) -> LiteTableCell {
    var viewObjects: NSArray?
    guard nib.instantiate(withOwner: self, topLevelObjects: &viewObjects) else {
      fatalError("Nib cannot be instantiated")
    }
    return (viewObjects!.first { $0 is LiteTableCell } as! LiteTableCell)
  }
  
  // MARK: - Cursor movement
  /**
   Move down the cursor
  */
  private func moveDown() {
    if let nextCell = currentCell.next() {// Next view is on screen
      currentIndex += 1
      highlightedCell = nextCell
    } else if currentIndex + 1 < liteDataSource?.numberOfCells(self) ?? 0 {// Next view can be loaded (scroll)
      if let top = displayDeque.removeFirst() {// Remove the cell on top
        reuseQueues[top.identifier!, default: []].appendLast(top)// Add to the reuse queue
        removeView(top.view)// Remove from LiteTableView
      }
      guard // Get the next cell
        let newCell = liteDataSource?.prepareCell(self, at: currentIndex + 1)
      else { return }
      currentIndex += 1
      displayDeque.appendLast(newCell)
      _ = currentCell.next()// Move iterator
      addView(newCell.view, in: .bottom) // Add to the LiteTableView
      highlightedCell = newCell
      liteDelegate?.viewDidScroll?(self)// Callback
    }
    // If at the bottom, do nothing
  }
  
  /**
   Move up the cursor
  */
  private func moveUp() {
    if let prevCell = currentCell.previous() {// If the previous view is visible
      currentIndex -= 1
      highlightedCell = prevCell
    } else if currentIndex - 1 >= 0 {// If the previous view is not visible
      if let bottom = displayDeque.removeLast() {// Remove the bottom view
        reuseQueues[bottom.identifier!, default: []].appendLast(bottom)
        removeView(bottom.view)
      }
      guard // Get the previous view
        let newCell = liteDataSource?.prepareCell(self, at: currentIndex - 1)
      else { return }
      currentIndex -= 1
      displayDeque.appendFirst(newCell)
      _ = currentCell.previous() // Move cursor
      insertView(newCell.view, at: 0, in: .top) // Add view to the top
      highlightedCell = newCell
      liteDelegate?.viewDidScroll?(self)// Callback
    } else {// If the view is above the top
      reset() // Reset
    }
  }
}
