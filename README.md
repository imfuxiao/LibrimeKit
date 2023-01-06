# LibrimeKit

[中州韻輸入法引擎／Rime Input Method Engine](https://github.com/rime/librime) to iOS Platform

使用 SwiftPackageManger 对 librime 封装. 方便 iOS 应用集成.


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

1. `librime-lua`插件编译成功, 但无法使用. 程序无法加载此插件. 暂时还未解决.