//
//  Pipeline.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import ArgumentParser
import Files
import Path

public enum FixMode: String, ExpressibleByArgument {
    case sdk            //修复组件的源码
    case app            //修复组件的 demo 工程
    case shell          //修复壳工程下面 Pods 目录里的内容
    case convert        //根据指定 pod 的信息进行头文件的转换, 组件拆分场景
}

public final class Pipeline {
    let mode: FixMode
    var referencePath: String
    var targetPath: String
    var patchFilePath: String?
    let needOverwrite: Bool
    
    public init(mode: FixMode,
                referencePath: String,
                targetPath: String,
                patchFilePath: String?,
                overwrite: Bool) throws {
        self.referencePath = Path(referencePath)?.string ?? (Path.cwd/referencePath).string
        self.mode = mode
        self.targetPath = Path(targetPath)?.string ?? (Path.cwd/targetPath).string
        if let patch = patchFilePath {
            self.patchFilePath = Path(patch)?.string ?? (Path.cwd/patch).string
        }
        self.needOverwrite = overwrite
        
        print("🚀 开始进行参数校验".likeSeperateLine(.normal))
        let inputChecker = InputChecker(mode: self.mode,
                                        referencePath: self.referencePath,
                                        targetPath: self.targetPath,
                                        patchFilePath: self.patchFilePath,
                                        overwrite: self.needOverwrite)
        try inputChecker.validate()        
    }
    
    public func run() throws {
        print("🚀 开始建立组件与头文件的映射关系索引表".likeSeperateLine(.normal))
        // 获取 header 的映射表
        var mapTable = try HeaderMapTable.init(referencePath: self.referencePath,
                                               mode: self.mode)
        // 增加注入映射表的能力
        if let path = self.patchFilePath {
            print("🚀 开始为映射关系索引表打补丁".likeSeperateLine(.normal))
            try mapTable.updateWith(patchFile: path)
        }
        print("🚀 对映射关系索引表进行自检".likeSeperateLine(.normal))
        // 诊断映射表自身存在的问题
        mapTable.doctor()

        print("🚀 开始查找需要检查/修复/转换的源文件信息".likeSeperateLine(.normal))
        // 获取 source file 的目录
        let sourceFiles = try ProjectSourceFiles.init(targetPath: targetPath,
                                                      mode: mode)

        print("🚀 开始进行头文件的检查/修复/转换".likeSeperateLine(.normal))
        // 修复头文件引用问题
        let sanitizer = Sanitizer(reference: mapTable,
                                  mode: mode,
                                  target: sourceFiles,
                                  needOverwrite: self.needOverwrite)
        // 根据 special pods 决定是否开启 write 模式
        try sanitizer.scan()
    }
}
