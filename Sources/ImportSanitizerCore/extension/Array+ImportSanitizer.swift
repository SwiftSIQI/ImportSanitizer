//
//  Array+ImportSanitizer.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/30.
//

import Foundation

public extension Array where Element: Equatable {
   // 去除数组重复元素
   func removeDuplicate() -> Array {
      return self.enumerated().filter { (index,value) -> Bool in
           return self.firstIndex(of: value) == index
       }.map { (_, value) in
           value
       }
   }
}
