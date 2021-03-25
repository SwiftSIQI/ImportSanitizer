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
    
    init(reference: HeaderMapTable, mode: FixMode, target: ProjectSourceFiles, needOverwrite: Bool) {
        self.reference = reference
        self.mode = mode
        self.target = target
        self.needOverwrite = needOverwrite
    }
        
    func scan() throws {
        // 创建处理器
        let processer: SanitizerProcess;
        switch self.mode {
        case .app, .sdk, .shell:
            processer = Formatter(mode: self.mode, reference: self.reference,
                                  target: self.target, needOverwrite: self.needOverwrite)
        case .convert:
            processer = Converter(mode: self.mode, reference: self.reference,
                                  target: self.target, needOverwrite: self.needOverwrite)
        }
        for file in self.target.sourceFiles {
            var content = try String(contentsOfFile: file.path)
            let syntaxArray = try ImportSyntax.searchImportSyntax(in: content)
            for syntax in syntaxArray {
                let needCheck = try processer.check(importSyntax: syntax, in: file)
                if needCheck {
                    content = try processer.fix(importSyntax: syntax, in: content, with: file)
                }
            }
            if needOverwrite {
                try file.write(content)
            }
        }
    }
}
