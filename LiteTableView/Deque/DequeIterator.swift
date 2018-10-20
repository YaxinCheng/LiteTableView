//
//  DequeIterator.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

/**
 A deque iterator begins at a certain node, and can move forward and backword
 */
struct DequeIterator<T>: IteratorProtocol {
  typealias Element = T
  /**
   The current node where the iterator is at
  */
  private var current: Deque<T>.Node<T>?
  /**
   Indicates if the the deque is at the first node
  */
  private var firstNode: Bool
  
  /**
   Constructor
   
   - parameter beginNode: the node where the iterator should begin iterating
  */
  init(beginNode: Deque<T>.Node<T>?) {
    current = beginNode
    firstNode = true
  }
  
  mutating func next() -> T? {
    if firstNode {
      firstNode = false
      return current?.content
    } else {
      guard current?.next != nil else { return nil }
      current = current?.next
      return current?.content
    }
  }
  
  /**
   Retreats to the previous element and returns it, or nil if no next element exists.
  */
  mutating func previous() -> T? {
    if firstNode { return nil }
    guard current?.prev != nil else {
      firstNode = true
      return nil
    }
    current = current?.prev
    return current?.content
  }
  
  /**
   Get the content from the current node
  */
  var content: T? {
    return current?.content
  }
}
