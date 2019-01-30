//
//  Deque.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

/**
 Deque is a double-ended queue, a linkedlist type data structure
 
 In this project, it is used to keep the visible cells
 */
struct Deque<T> {
  /**
   The element for deque is node. A deque is a chain of nodes
   */
  final class Node<T>: CustomStringConvertible {
    /**
     The content held inside the node
    */
    let content: T
    /**
     A pointer to the next node
    */
    var next: Node<T>? = nil
    /**
     A pointer to the previous node
    */
    weak var prev: Node<T>? = nil
    
    /**
     Constructor
     
     - parameter content: the content needs to be stored
    */
    init(_ content: T) {
      self.content = content
    }
    
    var description: String {
      return "\(content)"
    }
  }
  
  /**
   The first node of the deque
  */
  private var head: Node<T>? = nil
  /**
   The last node of the deque
   */
  private weak var tail: Node<T>? = nil
  /**
   The content in the first node
   */
  var first: T? { return head?.content }
  /**
   The content in the last node
   */
  var last: T? { return tail?.content }
  
  /**
   A semaphore is used to make the deque thread-safe
   */
  private let semaphore: DispatchSemaphore
  /**
   The number of nodes the deque has
   */
  var count: Int
  
  /**
   Constructor
   */
  init() {
    count = 0
    semaphore = DispatchSemaphore(value: 1)
  }
  
  /**
   Add some content to the beginning of the deque (async)
   
   - parameter newElement: the content that needs to be added
   */
  private mutating func appendFirstAsync(_ newElement: T) {
    let node = Node(newElement)
    if head != nil {
      node.next = head
      head?.prev = node
      head = node
    } else {
      head = node
      tail = node
    }
    count += 1
  }
  
  /**
   Add some content to the beginning of the deque
   
   - parameter newElement: the content that needs to be added
   */
  mutating func appendFirst(_ newElement: T) {
    semaphore.wait()
    appendFirstAsync(newElement)
    semaphore.signal()
  }
  
  /**
   Add a sequence of content to the beginning of the deque
   
   - parameter sequence: the sequence that needs to be added
   */
  mutating func appendFirst<V: Sequence>(contentOf sequence: V) where V.Element == T {
    semaphore.wait()
    for element in sequence {
      appendFirstAsync(element)
    }
    semaphore.signal()
  }
  
  /**
   Add some content to the end of the deque (async)
   
   - parameter newElement: the content that needs to be added
   */
  private mutating func appendLastAsync(_ newElement: T) {
    let node = Node(newElement)
    if tail != nil {
      tail?.next = node
      node.prev = tail
      tail = node
    } else {
      head = node
      tail = node
    }
    count += 1
  }
  
  /**
   Add some content to the end of the deque
   
   - parameter newElement: the content that needs to be added
   */
  mutating func appendLast(_ newElement: T) {
    semaphore.wait()
    appendLastAsync(newElement)
    semaphore.signal()
  }
  
  /**
   Add a sequence of content to the end of the deque
   
   - parameter newElement: the sequence that needs to be added
   */
  mutating func appendLast<V: Sequence>(contentOf sequence: V) where V.Element == T {
    semaphore.wait()
    for element in sequence {
      appendLastAsync(element)
    }
    semaphore.signal()
  }
  
  /**
   Remove the first node from the deque (async)
   
   - returns: the content in the removed node. Can be nil if the deque is empty
   */
  private mutating func removeFirstAsync() -> T? {
    guard head != nil else { return nil }
    let next = head?.next
    next?.prev = nil
    head?.next = nil
    let value = head?.content
    head = next
    count -= 1
    return value
  }
  
  /**
   Remove the first node from the deque
   
   - returns: the content in the removed node. Can be nil if the deque is empty
   */
  mutating func removeFirst() -> T? {
    semaphore.wait()
    let value = removeFirstAsync()
    semaphore.signal()
    return value
  }
  
  /**
   Remove the last node from the deque (async)
   
   - returns: the content in the removed node. Can be nil if the deque is empty
   */
  private mutating func removeLastAsync() -> T? {
    let value: T?
    if tail == nil {
      head = nil
      value = nil
    } else {
      if tail === head {
        value = tail?.content
        tail = nil
        head = nil
      } else {
        let prev = tail?.prev
        value = tail?.content
        tail?.next = nil
        prev?.next = nil
        tail = prev
      }
    }
    count -= 1
    return value
  }
  
  /**
   Remove the first node from the deque
   
   - returns: the content in the removed node. Can be nil if the deque is empty
   */
  mutating func removeLast() -> T? {
    semaphore.wait()
    let value = removeLastAsync()
    semaphore.signal()
    return value
  }
  
  /**
   Remove all the nodes from the deque
  */
  mutating func removeAll() {
    semaphore.wait()
    for _ in 0 ..< count {
      _ = removeFirstAsync()
    }
    semaphore.signal()
  }
}

extension Deque: Collection {
  func index(after i: Int) -> Int {
    return i + 1
  }
  
  subscript(position: Int) -> T {
    guard position >= startIndex, position < endIndex else { fatalError("Index out of range") }
    for (index, value) in self.enumerated() {
      if index == position { return value }
    }
    fatalError("Wrong index")
  }
  
  var startIndex: Int {
    return 0
  }
  
  var endIndex: Int {
    return count
  }
}

extension Deque: Sequence {
  func makeIterator() -> DequeIterator<T> {
    return Iterator(beginNode: head)
  }
}

extension Deque: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: T...) {
    self.init()
    for element in elements {
      appendLast(element)
    }
  }
}
