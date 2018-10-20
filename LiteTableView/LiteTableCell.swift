//
//  LiteTableCell.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

/**
 The superclass for all cells loaded in the LiteTableView
*/
open class LiteTableCell: NSCollectionViewItem {
  
  deinit {
    view.removeFromSuperview()
  }
  
  /**
   A bool value indicates if the cell is highlighted
  */
  open private(set) var highlighted: Bool = false
  /**
   The colour for a highlighted cell
  */
  open var highlightedColour: NSColor {
    if #available(OSX 10.14, *) {
      return .controlAccentColor
    } else {
      return .blue
    }
  }
  
  /**
   Switch the highlight state of cell
  */
  open func highlightToggle() {
    highlighted = !highlighted
    let colour: NSColor = highlighted ? highlightedColour : .clear
    view.layer?.backgroundColor = colour.cgColor
  }
}
