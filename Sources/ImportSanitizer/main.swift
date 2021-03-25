//
//  main.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import ImportSanitizerCore
import ArgumentParser

struct ImportSanitizer: ParsableCommand {
    @Option(name: .shortAndLong,
            help: "用来决定当前命令行工作在何种文件结构下工作, 可选的参数有 'sdk', 'app', 'shell', 'convert'.")
    var mode: FixMode = FixMode.sdk
    
    @Option(name: .shortAndLong,
            help: "需要传入建立组件和头文件映射关系表的文件目录, 在 convert 模式下,为 Pods 目录或者 Pods 的子目录,其余模式为 '.podfile' 文件的路径.")
    var referencePath: String = ""
    
    @Option(name: .shortAndLong,
            help: "需要传入被修改文件的路径,在 sdk 和 convert 模式下, 需要传入 '.podspec.json' 文件的路径; 在 app 模式下, 需要传入 app 工程的代码路径; 在 shell 模式下,需要传入 Pods 目录或者 Pods 的子目录.")
    var targetPath: String = ""

    @Option(name: [.customShort("p"), .customLong("patch-file")],
            help: "修改组件和头文件的映射表的补丁文件")
    var patchFilePath: String?
    
    @Option(name: .shortAndLong,
            help: "是否对待修改文件进行写入操作")
    var overwrite: Bool = true
    
    @Flag(name: .shortAndLong,
          help: "显示命令行工具的版本号信息.")
    var version: Bool = false
        
    mutating func run() throws {
        guard version == false else {
            print(IMPORT_SANITIZER_VERSION)
            return
        }
        print("""
        欢迎使用 Import Sanitizer 😘
        原始参数信息如下👇
        Mode 参数为                 \(mode)
        Reference Path 参数为       \(referencePath)
        Target Path 参数为          \(targetPath)
        Patchfile Path 参数为       \(patchFilePath ?? "nil")
        Overwrite State 参数为      \(overwrite)
        """)
        do {
            let pipeline = try Pipeline(mode: mode,
                                        referencePath: referencePath,
                                        targetPath: targetPath,
                                        patchFilePath: patchFilePath,
                                        overwrite: overwrite)
            try pipeline.run()
            print("🎉 Import Sanitizer 运行完成".likeSeperateLine(.normal))
        } catch  {
            print("🚧 Import Sanitizer 运行中断".likeSeperateLine(.normal))
            if let impsError = error as? ImportSanitizerError {
                print("运行过程中发生了错误, 详细信息为: \(impsError.message)".likeFailed)
            } else {
                print("运行过程中发生了错误, 详细信息为: \(error)!".likeFailed)
            }
        }
    }
}

ImportSanitizer.main()
