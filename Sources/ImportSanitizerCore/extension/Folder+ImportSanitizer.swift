//
//  Folder+ImportSanitizer.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

extension Folder {
    func sourceFileInProject() -> [File] {
        return self.files.recursive.filter{
            $0.extension == "h"     ||
            $0.extension == "m"     ||
            $0.extension == "mm"    ||
            $0.extension == "pch"
        }
    }
}
