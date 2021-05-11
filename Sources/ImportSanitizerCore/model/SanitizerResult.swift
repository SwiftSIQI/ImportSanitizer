//
//  SanitizerResult.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2021/5/11.
//

import Foundation

public enum SyntaxErrorType: String {
    case noSlash                = "没有使用组件名/头文件的格式"
    case quotationWithSlash     = "没有使用尖括号"
    case duplicatedHeaderFile   = "存在重名头文件"
    case duplicatedSyntax       = "重复引用头文件"
    case implementationFile     = "引入了'.m'类型的文件"
}


public enum SolutionType: String {
    case automatically          = "自动修复"
    case manually               = "手动修复"
}

public struct Description : Codable {
    var syntax: String
    var fileName: String
    var filePath: String
    var errorType: String
    var soulution: String
}

