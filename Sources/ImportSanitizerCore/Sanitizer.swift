//
//  Sanitizer.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

struct Sanitizer {
    let reference: HeaderMapTable
    let mode : FixMode
    let target : ProjectSourceFiles
    let needOverwrite: Bool
    var processer : SanitizerProcess
    
    init(reference: HeaderMapTable, mode: FixMode, target: ProjectSourceFiles, needOverwrite: Bool) {
        self.reference = reference
        self.mode = mode
        self.target = target
        self.needOverwrite = needOverwrite
        // 创建处理器
        switch self.mode {
        case .app, .sdk, .shell:
            self.processer = Formatter(mode: self.mode, reference: self.reference,
                                  target: self.target, needOverwrite: self.needOverwrite)
        case .convert:
            self.processer = Converter(mode: self.mode, reference: self.reference,
                                  target: self.target, needOverwrite: self.needOverwrite)
        }
    }
        
    mutating func scan() throws -> [String]{
        // 用于存储所有文件中的头文件语句
        var dependenceImportSyntax = [ImportSyntax]()
        for file in self.target.sourceFiles {
            var content = try String(contentsOfFile: file.path)
            let syntaxArray = try ImportSyntax.searchImportSyntax(in: content)
            for syntax in syntaxArray {
                let isValidate = self.processer.isValidate(syntax, in: file)
                let needCheck = try self.processer.check(importSyntax: syntax, in: file)
                if needCheck && isValidate {
                    content = try self.processer.fix(importSyntax: syntax, in: content, with: file)
                }
            }
            // 根据修改后的 content 进行去重
            let fixedSyntaxArray = try ImportSyntax.searchImportSyntax(in: content)
            var duplicatedSyntax = [ImportSyntax]()
            var syntaxTable = [String : ImportSyntax]()
            for syntax in fixedSyntaxArray {
                guard syntaxTable[syntax.raw] == nil else {
                    // 说明当前这个头文件已经引用过了,是可以删除的
                    duplicatedSyntax.append(syntax)
                    continue
                }
                syntaxTable[syntax.raw] = syntax
            }
            // 根据 duplicatedSyntax 的值删除重复内容
            for syntax in duplicatedSyntax {
                let range = NSRange(location: 0, length:content.count)
                let pattern = syntax.raw
                    .replacingOccurrences(of: "+", with: "\\+")
                    .replacingOccurrences(of: "/", with: "\\/")
                let regex = try NSRegularExpression(pattern: pattern,
                                                    options: .caseInsensitive)
                let firstResult = regex.firstMatch(in: content, options: .reportProgress, range: range)
                if let firstTarget = firstResult {
                    content = regex.stringByReplacingMatches(in: content,
                                                            options: .reportProgress,
                                                            range: firstTarget.range,
                                                            withTemplate: "")
                    let aSyntax = syntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)
                    let eType = SyntaxErrorType.duplicatedSyntax.rawValue
                    let sType = SolutionType.automatically.rawValue
                    let solution = "删除多余的 \(aSyntax)"
                    let description = Description(syntax: aSyntax, fileName: file.name, filePath: file.path, errorType: eType, soulution: solution)
                    self.processer.result.append(description)
                    print("错误类型为[\(eType)], 修复方式为[\(sType)], 错误语句为[\(aSyntax)], 解决方案为 \(solution), 问题发生在 \(file.name) 中".determined(by: needOverwrite))
                }
            }
            // 将当前文件里的所有头文件引用保存起来
            dependenceImportSyntax.append(contentsOf: syntaxTable.values)
            // 根据 needOverwrite 决定是否覆盖原文件
            if needOverwrite {
                try file.write(content)
            }
        }
        // 对所有依赖的组件进行统计
        return dependenceImportSyntax.map { (item) -> String? in
            guard let info = item.info else { return nil }
            let parts = info.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "/")
            guard parts.count >= 2 else { return nil }
            return String(parts.first!)
        }.compactMap{$0}.removeDuplicate()
    }
    
    func printDependence(_ dependencePods: [String]) -> Void {
        print("此工程显示依赖以下组件,它们分别是:")
        for pod in dependencePods {
            print("\(pod)")
        }
    }
    
    func saveResultToLocal(_ path: String, mode: FixMode) throws -> Void {
        guard self.processer.result.count > 0 else {
            print("此次扫描没有错误,无须保存任何信息到本地")
            return
        }
        var folderPath: String? = ""
        // 因为前面进行过 input 参数检查,这里可以直接强制解包
        switch mode {
        case .convert:
            folderPath = try Folder(path: path).parent?.path
        case .app, .shell, .sdk:
            folderPath = try File(path: path).parent?.path
        }
        let fileURL = URL(fileURLWithPath: "\(folderPath!)" + "imps_sanitizer_result.json")
        let content = self.processer.result
        let jsonData = try JSONEncoder().encode(content)
        try jsonData.write(to: fileURL, options: [.atomicWrite])
        print("扫描结果已经保存在 \(fileURL.absoluteString)")
    }
}
