//
//  LiteTableDelegate.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

@objc public protocol LiteTableDelegate {
  @objc optional func keyPressed(_ event: NSEvent)
  @objc optional func viewDidScroll(_ tableView: LiteTableView)
}

@objc public protocol LiteTableDataSource {
  func cellReuseThreshold(_ tableView: LiteTableView) -> Int
  func numberOfCells(_ tableView: LiteTableView) -> Int
  func cellHeight(_ tableView: LiteTableView) -> CGFloat
  func prepareCell(_ tableView: LiteTableView, at index: Int) -> LiteTableCell
}
