//
//  LiteTableDelegate.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

/**
 LiteTableDelegate is a group of callback functions called by the tableView when certain actions happened
 */
@objc public protocol LiteTableDelegate {
  /**
   Delegate function when key is pressed
   - parameter event: the key pressed event
  */
  @objc optional func keyPressed(_ event: NSEvent)
  /**
   Callback function when the view is "scrolled"
   
   The tableView does not "scroll", but it shows like a scrolling when removing the **top** cell and appending a **bottom** cell
   
   - parameter tableView: the tableView which is "scrolled"
  */
  @objc optional func viewDidScroll(_ tableView: LiteTableView)
}

/**
 LiteTableDataSource is a group of functions called by the LiteTableView when it is loading/reloading the cells. The tableView delegates the detailed cell configurations to the user
 */
@objc public protocol LiteTableDataSource {
  /**
   Defines how many cells should be on the same page
   
   LiteTableView would only load this number of cells. The extra ones are loaded when there's a space for them. Basically, it is a lazy loading
   
   - parameter tableView: the tableView which requires this information
   - returns: an integer number of the maximum visible cells at once
  */
  func cellReuseThreshold(_ tableView: LiteTableView) -> Int
  /**
   Defines the number of cells in total that will be displayed by the tableView
   
   - parameter tableView: the tableView which requires this information
   - returns: an integer number of the total cells need to be displayed
  */
  func numberOfCells(_ tableView: LiteTableView) -> Int
  /**
   Defines the cell height. All cells should be with the same height
   
   - parameter tableView: the tableView which requires this information
   - returns: the cell height
  */
  func cellHeight(_ tableView: LiteTableView) -> CGFloat
  /**
   Defines the cell view at a certain index
   
   This method is called by the tableView when it is *reloading* or *loading*. Cells will be automatically during the process. To get a cell, call `dequeueCell(NSUserInterfaceItemIdentifier) -> LiteTableCell`
   
   - parameter tableView: the tableView which requires this information
   - parameter index: the index for required data
   - returns: a constructed and configured cell
  */
  func prepareCell(_ tableView: LiteTableView, at index: Int) -> LiteTableCell
}
