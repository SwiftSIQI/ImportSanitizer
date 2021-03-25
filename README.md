## 背景

不规范的头文件引用是 C 系语言开发过程中的不可回避的一个问题。

例如在 iOS 的工程文件中，我们经常会看到开发者使用各种姿势引用其他组件，例如 `#import "Core.h"`, `#import <Core.h>` 和 `#import "A/Core.h"`，这些写法较 `#import <A/Core.h>` 来说都是非标准写法，同时也会带来许多问题：

1. 非标准写法会造成项目的 `search path` 变得冗长，进而引起编译耗时加剧，在极端情况下，字段过长还会触发无法编译的问题。
2. 在开启 Clang Module 后，非标准写法无法自动转换为 module 引入，编译速度无法提升。

然而，即使你使用了 `#import <A/Core.h>` 的写法，也还是会遇到一些令人困扰的问题！

例如当我们把 A 组件拆分成 `A-Core` 和 `A-Business` 两个库后，原先的引入方式需要改变，例如原先的 `#import <A/Core.h>` 写法就要变成  `#import <A-Core/Core.h>`，虽然看起来好像不是什么大问题，但对于有几百个组件的大工程而言，这种变化会给其他开发者带来许多困扰，尤其是拆分的组件为底层基建的时候，这种影响和改动成本会是难以估计的。

除了组件拆分的场景外，在组件迁移的场景下（例如我要下线 A 组件，转而用 B 组件的情况），头文件引用内容的变更也会令开发者烦恼。

为了解决这些问题，Import Sanitizer 诞生了！

**它是一款能够帮助开发者自动解决工程中各类头文件引用问题的 CLI 工具**，简单，高效，全能的它会让你爱不释手！

> 为了简化说明，将用 IMPS 的简写来指代 Import Sanitizer

## 安装方式

### 通过 命令行 进行安装

```sh
/bin/zsh -c "$(curl -fsSL https://s3plus-corp.sankuai.com/v1/mss_fc3411bb1ab342d4baee3a99d29d0503/artifacts/importsanitizer-install.sh)"
```

### 通过源码进行安装

* 在 Github 上下载项目源码
* 编译工程，生成二进制文件并移动至 bin 目录下
* 修改可执行文件权限

```sh
$ swift build --configuration release
$ cp -f .build/release/importsanitizer /usr/local/bin/imps
$ cd /usr/local/bin
$ sudo chmod -R 777 imps
```

## 使用详解

### 快速使用

假设 A 组件有如下所示的文件结构，这也是 CocoaPods 创建组件时的默认文件结构，其中 `A.podspec.json` 文件是通过 `pod ipc spec` 命令获得的。

```
├── Example
│   ├── Podfile
│   ├── Podfile.lock
│   ├── Pods
│   ├── A
│   ├── A.xcodeproj
│   ├── A.xcworkspace
│   └── Tests
├── LICENSE
├── README.md
├── A
│   ├── Assets
│   └── Classes
├── A.podspec
├── A.podspec.json
```

你只需要输入如下命令，即可完成头文件引用格式的检查与修改！

```shell
$ imps -m sdk -r './Example/Podfile' -t './A.podspec.json'
```

### 参数详解

#### `-m` 参数

`-m` 是 `--mode` 的缩写，参数用于决定该命令行工具的运行模式，目前支持以下四种参数：

* sdk 模式：用于检查组件源码的头文件引用问题，例如组件 A 的源码引用问题(`./A/Classes`目录)
* app 模式：用于检查 App 的头文件引用问题，例如组件 A 的 Example 工程的源码引用问题（`./Example/A`目录）
* shell 模式：用于检查 App 依赖组件的头文件引用问题，例如组件 A 的 Example 工程的 Pods 目录的源码引用问题（`./Example/Pods`）
* convert 模式：用于组件拆分，组件下线或者组件迁移的场景，将原有代码中的头文件引用关系指向新的组件，例如将 `#import <A/Core.h>`， `#import <Core.h>` 等写法自动转换成  `#import <A-Core/Core.h>`

#### -r 和 -t 参数

`-r` 是 `--reference-path` 的缩写，用于建立头文件和组件的映射关系表，是之后进行头文件格式检查及转换的依据来源。
`-t` `--target-path` 的缩写，用于决定哪些路径下的文件需要被修改，可以是 `podspec.json` 类型的文件，也可以是具体的文件目录。

| 模式    | -r 参数 | -t 参数 |
| :---    | :----   | :----   |
| sdk     | 指向宿主工程中的 podfile 文件      | 指向组件的 `podspec.json` 文件           |
| app     | 指向 App 工程的 podfile 文件       | 指向 App 工程的源码目录                |
| shell   | 指向 App 工程的 podfile 文件       | 指向 App 工程的 Pods 目录或者其子目录  |
| convert | 指向 App 工程的 Pods 目录的子目录  | 指向组件的 `podspec.json` 文件           |

#### -o 参数

`-o` 是 `--overwrite` 的缩写，用于决定是否对不规范的写法进行覆盖，如果设置为 false，则只检查，不修改，设置为 true ，则在检查的同时，直接修改源文件中的不规范写法，默认值为 true。

#### -p 参数

`-p` 是`--patch-file` 的缩写，用于修正头文件和组件的映射关系表的文件路径，该功能是通过加载指向的 json 文件来改变映射表的行为！

在实际的开发场景中，会存在重名同名头文件的情况，即 A 组件和 B 组件里都有 `Core.h` 文件，但引用时只写了 `#import <Core.h>` 或者 `#import “Core.h”`，此时该工具无法判断开发者的意图，也无法进行引用格式的转换。

为了解决这个问题，可以生成一个 json 文件，用于描述你所期望的转换关系，例如下面的 `MapTablePatch.json` 文件，它的内容如下：

```json
[
  { "name":"Core.h", "pod":"B" }
]
```

在执行 imps 的时候添加 `-p` 参数并指向该文件

```sh
$ imps ... --patch-file './x/.../MapTablePatch.json'
```

通过这种方式，即使 `Core.h` 在 A, B 两个组件中都存在，在实际的转换过程中，也只会生成 `#import <A/A.h>` 的引用方式。

#### -v 参数

`-v` 是 `--version` 的缩写，用于显示当前工具的版本号

#### -h 参数

`-h` 是 `--help` 的缩写，以下是该工具的帮助文档

```sh
USAGE: import-sanitizer [--mode <mode>] [--reference-path <reference-path>] [--target-path <target-path>] [--patch-file <patch-file>] [--overwrite <overwrite>] [--version]

OPTIONS:
  -m, --mode <mode>       用来决定当前命令行工作在何种文件结构下工作, 可选的参数有 'sdk', 'app', 'shell',
                          'convert'. (default: sdk)
  -r, --reference-path <reference-path>
                          需要传入建立组件和头文件映射关系表的文件目录, 在 convert 模式下,为 Pods 目录或者
                          Pods 的子目录,其余模式为 '.podfile' 文件的路径.
  -t, --target-path <target-path>
                          需要传入被修改文件的路径,在 sdk 和 convert 模式下, 需要传入
                          '.podspec.json' 文件的路径; 在 app 模式下, 需要传入 app 工程的代码路径; 在
                          shell 模式下,需要传入 Pods 目录或者 Pods 的子目录.
  -p, --patch-file <patch-file>
                          修改组件和头文件的映射表的补丁文件
  -o, --overwrite <overwrite>
                          是否对待修改文件进行写入操作 (default: true)
  -v, --version           显示命令行工具的版本号信息.
  -h, --help              Show help information.
```

## Q & A

### 各个模式会依据是什么逻辑进行修复和检查呢？

在 sdk，app 和 shell 模式下，所有非 `#import <A/Core.h>` 的写法都将会被检查

* 对于 `#import “A/Core.h”` 的写法，会直接将 `“”` 转换为 `<>`
* 对于 `#import <Core.h>` 和 `#import “Core.h”` 的写法，除了将 `“”` 转换为 `<>` 外，还会判断当前头文件是否属于组件自身，只有非组件内部的引用才会转换为 `#import <A/Core.h>` ，组件内的引用将保持原状。

在 convert 模式下，所有引入头文件的写法都会被检查，并统一转换为 `#import <A/Core.h>` 的形式。

### 使用工具时，有什么需要注意的地方么？

* 在 sdk，app 和 shell 模式下，工具自身的定位是**解决不规范头的文件引用格式**，而非引入内容的正确性！
  * 对于 `#import <A/Core.h>` 和 `#import “A/Core.h”` 的格式而言，工具不会检查 `Core.h` 是否属于 A 组件，对于这两种类型，工具只会跳过操作或者机械的将 `“”` 转换为 `<>` 的写法。 
  * 对于 `#import <Core.h>` 和 `#import “Core.h”` 的格式而言，在转换过程中由于缺少组件名信息，才会进行一次检索。
  * 我们认为头文件引入内容的正确性，应当是在开发过程中就必须解决的，不会出现无法编译就发布产品的情况，所以基于这个认知，我们认为当下的修复策略能避免不必要的检索和查询，进一步提升工具的使用效率。
  * *未来可能会提供更完备的检查能力，既能检查格式的正确性，也能检查内容的正确性，*
  
* 在 convert 模式下，需要注意重名头文件的情况！
  * 需要保证 `-r` 目录下的文件，与 `-t` 指向的文件没有重名，否则将无法转换

### `podspec.json` 类型的文件是怎么来的？

请记住，这个功能是 CocoaPods 提供的，而非 IMPS 提供的，需要先保证自己安装了 CocoaPods，然后在 `podspec` 文件所在的目录中，执行如下命令，即可获得对应的 `podspec.json` 文件

```shell
$ pod ipc spec LibraryName.podspec >> LibraryName.podspec.json
```

### 关于组件拆分和组件迁移

convert 模式主要用于组件拆分，组件迁移的场景，例如：

* 组件拆分：将组件 A 拆成了 Core 和 Utility 两个库时，其他组件对于 A 的引用如何变成 Core 和 Utility
* 组件迁移：将组件 A 的部分头文件放到了组件 B 中，其他组件对于 A 的引用如果变成 B 的引用

要想使用 IMPS 处理上面的场景，需要保证头文件的名称不发生变化，否则将无法使用。

### 目前有什么 bug 么？

* 如果组件的 `podspec` 里有 `header_dir`，`header_mappings_dir` 或者 `module_name` 字段，命令行执行可能会出现与预期不符的情况，主要原因是因为这些字段会改变其在 `Pods/Headers/Public/` 和 `Pods/Headers/Private/` 下的文件结构，进而导致头文件的引入方式和命令行的行为不一致

* 需要确保宿主工程里只有一个 Development Pods，也就是 Podfile 中只允许有一个指向本地的组件，否则在构建索引表的时候会出现缺失组件信息的情况，这个问题原因是在构建索引表的时候强依赖 Pods 目录的文件结构，Development Pods 不会添加到当前目录中，进而导致命令行行为异常

以上两个问题为已知问，目前正在积极适配中！

## TODO

* 支持 homebrew 的安装方式
* 兼容 `.c`，`.cpp`，`.hpp` 等格式的文件
* 优化构建组件和头文件的映射关系表，兼容 `header_dir`，`header_mappings_dir` 及 `module_name` 字段在 CocoaPods 的行为
* 增加检查内容正确性的能力，即引入 `#import <A/A.h>` 和 `#import "A/A.h"` 的时候，判断 `A.h` 是否属于 A 组件
* 增加组件下线的能力
