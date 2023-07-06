# LibrimeKit

[中州韻輸入法引擎／Rime Input Method Engine](https://github.com/rime/librime) to iOS Platform

将 librime 编译为 iOS 项目使用的二进制包，供 iOS 平台代码调用。

> 注意：
> 这个项目开始是包含在 Swift package manager 中的，里面包含了 OC 和 Swift 对 librime api的封装。
> 从 hamster 的2.0开始，重构了项目代码，移除了这个项目的代码，相关代码移动到 Hamster 的 RimeKit 中。
> 目前这个项目只用来编译二进制的 framework 包。

## 依赖项目

* [librime](https://github.com/rime/librime): 中州韻輸入法引擎
* [boost-iosx](https://github.com/imfuxiao/boost-iosx): boost to iOS

## 编译

1. 编译依赖boost

`make boost-build`

> 注意: 需要安装 cocoapods

2. 编译librime

`make librime-build`

> 注意: iOS商店审核不支持动态库. 所以必须编译为静态库

## 已知问题

1. `librime-lua`插件编译需要修改 librime 的源代码, 后续看怎么改为不用改 librime 的源码.
