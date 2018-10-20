//
//  Deque.swift
//  LiteTable
//
//  Created by Yaxin Cheng on 2018-10-10.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

struct Deque<T> {
  final class Node<T>: CustomStringConvertible {
    let content: T
    var next: Node<T>? = nil
    weak var prev: Node<T>? = nil
    
    init(_ content: T) {
      self.content = content
    }
    
    var description: String {
      return "\(content)"
    }
  }
  
  private var head: Node<T>? = nil
  private weak var tail: Node<T>? = nil
  var first: T? { return head?.content }
  var last: T? { return tail?.content }
  
  private let semaphore: DispatchSemaphore
  var count: Int
  
  init() {
    count = 0
    semaphore = DispatchSemaphore(value: 1)
  }
  
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
  
  mutating func appendFirst(_ newElement: T) {
    semaphore.wait()
    appendFirstAsync(newElement)
    semaphore.signal()
  }
  
  mutating func appendFirst<V: Sequence>(contentOf sequence: V) where V.Element == T {
    semaphore.wait()
    for element in sequence {
      appendFirstAsync(element)
    }
    semaphore.signal()
  }
  
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
  
  mutating func appendLast(_ newElement: T) {
    semaphore.wait()
    appendLastAsync(newElement)
    semaphore.signal()
  }
  
  mutating func appendLast<V: Sequence>(contentOf sequence: V) where V.Element == T {
    semaphore.wait()
    for element in sequence {
      appendLastAsync(element)
    }
    semaphore.signal()
  }
  
  private mutating func removeFirstAsync() -> T? {
    guard head != nil else { return nil }
    let next = head?.next
    head?.next = nil
    let value = head?.content
    head = next
    count -= 1
    return value
  }
  
  mutating func removeFirst() -> T? {
    semaphore.wait()
    let value = removeFirstAsync()
    semaphore.signal()
    return value
  }
  
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
  
  mutating func removeLast() -> T? {
    semaphore.wait()
    let value = removeLastAsync()
    semaphore.signal()
    return value
  }
  
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
