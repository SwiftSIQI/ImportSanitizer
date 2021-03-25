//
//  SanitizerProcess.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/12/23.
//

import Foundation
import Files

protocol SanitizerProcess {
    var mode : FixMode { get set }
    var reference: HeaderMapTable { get set }
    var target : ProjectSourceFiles { get set }
    var needOverwrite: Bool { get set }
    
    func check(importSyntax: ImportSyntax, in file: File) throws-> Bool
    func fix(importSyntax: ImportSyntax,
             in content: String,
             with file: File ) throws -> String
}

extension SanitizerProcess {
    func shouldIgnore(_ importSyntax: ImportSyntax, in file: File) -> Bool {
        // 1 获取 MapTable 中对应 header 的 pod 名称
        guard let headerName = importSyntax.headerName,
              let podNames = self.reference.mapTable[String(headerName)]  else {
            // 没有找到相应的头文件信息说明
            // 1. 可能是引用了某些特殊的系统文件 2. 可能是当前组件的源码文件
            return true
        }
        guard podNames.count == 1 else {
            // 说明有同名的头文件, 此时不做修复, 应当提醒开发者手动修改
            print("错误类型为 [存在重名头文件], 需要开发者手动修复, \(headerName) 同时属于以下组件 \(podNames), 发生在 \(file.name)".likeValuableSentence(.error))
            return true
        }
        return false
    }
}
