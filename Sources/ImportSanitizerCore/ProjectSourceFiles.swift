//
//  ProjectSourceFiles.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

struct ProjectSourceFiles {
    let targetPath : String
    let mode: FixMode
    var sourceFiles = [File]()
    var count: Int { sourceFiles.count }

    init(targetPath: String, mode: FixMode) throws {
        self.targetPath = targetPath
        self.mode = mode
        self.sourceFiles = try self.fetchSourceFiles(path: targetPath, mode: mode)
        print("需要检查/修复的源文件数量为: \(sourceFiles.count)")
    }
    
    func podspecInfo() throws -> PodSpec? {
        guard self.mode == .sdk else {
            return nil
        }
        return try Utility.fetchPodspecInfo(with: self.targetPath)
    }
}

extension ProjectSourceFiles {
    func fetchSourceFiles(path: String, mode: FixMode) throws -> [File] {
        // 核心逻辑 根据不同的模式获取 source file
        var files = [File]()
        switch mode {
        case .sdk, .convert:
            // 在 sdk , convert 模式下, 为 PODSPEC 里 source_file 描述的文件
            files = try self.gatherIn(podspecPath: path)
        case .shell:
            // 在 shell 模式下, 为 PODS 目录下的文件
            files = try self.gatherIn(podsPath: path)
        case .app:
            // 在 app 模式下, 为指定文件夹下的文件
            files = try self.gatherIn(appPath: path)
        }
        return files
    }
    
    // sdk, convert 模式下的文件
    func gatherIn(podspecPath: String ) throws -> [File] {
        var targetFiles = [File]()
        // 根据 podspec 的路径获取整个项目工程的相对根目录
        let podspec = try Utility.fetchPodspecInfo(with: podspecPath)
        
        guard let rootPath = try File(path: podspecPath).parent?.path else{
            return targetFiles
        }
        // 遍历 podspec 里的路径并拼接文件名
        var relativePaths = [String]()
        for info in podspec.sourceFilesAll() {
            let relativePathComponent = info.split(separator: "/")
            let cutIndex = relativePathComponent.firstIndex {(element) -> Bool in
                element.contains("*") || element.contains(".")
            }
            var result = [String.SubSequence]()
            if let end = cutIndex {
                result = Array(relativePathComponent[0..<Int(end)])
            } else {
                result = relativePathComponent
            }
                
            // 注意: 这里的代码注意是针对 podspec 里 A/B/{C,D,E,F} 写法进行兼容的逻辑
            let original = result.map { (element) -> Array<String> in
                if element.contains("{") && element.contains("}") {
                    return element.replacingOccurrences(of: "{", with: "")
                        .replacingOccurrences(of: "}", with: "")
                        .split(separator: ",")
                        .map{String($0).trimmingCharacters(in: NSCharacterSet.whitespaces)}
                } else {
                    return [String(element)]
                }
            }
            self.dfs(dep: 0, original: original, input: [], output: &relativePaths)
        }
        for relativePath in relativePaths {
            let folderPath = rootPath + relativePath
            let files = try Folder(path: folderPath).sourceFileInProject()
            targetFiles.append(contentsOf: files)
        }
        // 对 target files 去重
        let result = targetFiles.removeDuplicate()
        return result
    }
    
    // shell 模式下的文件
    func gatherIn(podsPath: String) throws -> [File] {
        var targetFiles = [File]()
        if try Folder(path: podsPath).name == "Pods" {
            // 如果指向的 Pods 目录
            let podsPath = podsPath
            let sdkNames = try Utility.fetchSDKNames(with: podsPath)
            // 通过组件名称构建一个 sdk 路径, 在这个路径下把所有文件名遍历并塞到映射表中
            for sdk in sdkNames {
                let sdkPath = podsPath + "/" + sdk
                let target = try Folder(path: sdkPath).sourceFileInProject()
                targetFiles.append(contentsOf: target)
            }
        } else {
            // 如果指向的是 Pods 目录里的
            let target = try Folder(path: podsPath).sourceFileInProject()
            targetFiles.append(contentsOf: target)
        }
        // 对 target files 去重
        let result = targetFiles.removeDuplicate()
        return result
    }
    
    // app 模式下的文件
    func gatherIn(appPath: String) throws -> [File] {
        // 根据指定目录获取
        let targetFiles = try Folder(path: appPath).sourceFileInProject()
        // 对 target files 去重
        let result = targetFiles.removeDuplicate()
        return result
    }
}

extension ProjectSourceFiles{
    // 使用递归的方法将  [["A","B"], ["C","D"]] 形式的数组转换成
    // A/C, A/D, B/C, B/D
    func dfs(dep: Int, original: [[String]], input: [String], output: inout [String]) {
        if dep == original.count {
            output.append(input.reduce("") { return $0 + "/" + $1 } )
            return
        }
        for cc in original[dep] {
            if dep != original.count {
                var nextCur = input
                nextCur.append(cc)
                dfs(dep: dep + 1, original: original, input: nextCur, output: &output)
            }
        }
    }
}
