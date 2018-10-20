//
//  LiteTableView.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

open class LiteTableView: NSStackView {
  @IBOutlet public weak var liteDelegate: LiteTableDelegate?
  @IBOutlet public weak var liteDataSource: LiteTableDataSource?
  private var displayDeque: Deque<LiteTableCell> = []
  private var registeredNibs: [NSUserInterfaceItemIdentifier: NSNib] = [:]
  private var registeredClasses: [NSUserInterfaceItemIdentifier: LiteTableCell.Type] = [:]
  private var reuseQueues: [NSUserInterfaceItemIdentifier: Deque<LiteTableCell>] = [:]
  
  private var keyboardMonitor: Any?
  
  public private(set) var highlightedCell: LiteTableCell? {
    willSet {
      if highlightedCell?.highlighted == true {
        highlightedCell?.highlightToggle()
      }
    } didSet {
      if highlightedCell?.highlighted == false {
        highlightedCell?.highlightToggle()
      }
    }
  }
  private lazy var currentCell: Deque<LiteTableCell>.Iterator = {
    return displayDeque.makeIterator()
  }()
  private var resetCurrFlag: Bool = false
  private var currentIndex: Int = -1
  public var allowedKeyCodes: Set<UInt16> = [125, 126]
  public var visibleCells: [LiteTableCell] {
    return Array(displayDeque)
  }
  
  public required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    translatesAutoresizingMaskIntoConstraints = false
    setUp()
  }
  
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setUp()
  }
  
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
  
  private func reset() {
    currentIndex = -1
    highlightedCell = nil
    currentCell = displayDeque.makeIterator()
  }
  
  deinit {
    guard keyboardMonitor != nil else { return }
    NSEvent.removeMonitor(keyboardMonitor!)
    keyboardMonitor = nil
  }
  
  public func reload() {
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
    resetCurrFlag = true
  }
  
  public func register(nib: NSNib, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
    registeredNibs[identifier] = nib
  }
  
  public func register(class: LiteTableCell.Type, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
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
  
  private func modifierChanged(with event: NSEvent) {
    
  }
  
  open override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if allowedKeyCodes.contains(event.keyCode) { return true }
    else { return super.performKeyEquivalent(with: event) }
  }
  
  public func dequeueCell(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> LiteTableCell {
    if reuseQueues[identifier] == nil { reuseQueues[identifier] = Deque<LiteTableCell>() }
    if reuseQueues[identifier]!.isEmpty {
      let cell: LiteTableCell
      if let nib = registeredNibs[identifier] {
        cell = load(fromNib: nib)
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
  
  private func load(fromNib nib: NSNib) -> LiteTableCell {
    var viewObjects: NSArray?
    guard nib.instantiate(withOwner: self, topLevelObjects: &viewObjects) else {
      fatalError("Nib cannot be instantiated")
    }
    return (viewObjects!.first { $0 is LiteTableCell } as! LiteTableCell)
  }
  
  private func moveDown() {
    if let nextCell = currentCell.next() {// Next view is on screen
      currentIndex += 1
      highlightedCell = nextCell
    } else if currentIndex + 1 < liteDataSource?.numberOfCells(self) ?? 0 {// Next view can be loaded
      if let top = displayDeque.removeFirst() {
        reuseQueues[top.identifier!, default: []].appendLast(top)
        removeView(top.view)
      }
      guard
        let newCell = liteDataSource?.prepareCell(self, at: currentIndex + 1)
        else { return }
      currentIndex += 1
      displayDeque.appendLast(newCell)
      _ = currentCell.next()
      addView(newCell.view, in: .bottom)
      highlightedCell = newCell
      liteDelegate?.viewDidScroll?(self)
    } else { return }
  }
  
  private func moveUp() {
    if let prevCell = currentCell.previous() {
      currentIndex -= 1
      highlightedCell = prevCell
    } else if currentIndex - 1 >= 0 {
      if let bottom = displayDeque.removeLast() {
        reuseQueues[bottom.identifier!, default: []].appendLast(bottom)
        removeView(bottom.view)
      }
      guard
        let newCell = liteDataSource?.prepareCell(self, at: currentIndex - 1)
        else { return }
      currentIndex -= 1
      displayDeque.appendFirst(newCell)
      _ = currentCell.previous()
      insertView(newCell.view, at: 0, in: .top) // Add view to the top
      highlightedCell = newCell
      liteDelegate?.viewDidScroll?(self)
    } else {
      reset()
    }
  }
}
