# xim-pkgindex-dragonos

xim package index for dragonos community

## 添加索引仓库

> 添加索引仓库到xim的索引仓库管理器中

```bash
xim --add-indexrepo dragonos:https://github.com/sunrisepeak/xim-pkgindex-dragonos.git
xim --update index
```

## 使用仓库中的包

> 一键配置环境 并获取内核代码(支持镜像路线自动选择) 

```bash
# 自动下载安装相关工具链 rust / make / qemu / dadk / dragonos-tool ...
xlings install dragonos:dragonos-dev
```

```bash
# dragon-tool init 在当前目录初始化项目(支持自动识别dadk版本并切换)
dotool init
dotool build # 支持自动重试机制(retry = 3)
dotool run
```

## 其他

- DragonOS社区: https://github.com/DragonOS-Community
- xlings包管理器: https://github.com/d2learn/xlings
- xlings论坛版块: https://forum.d2learn.org/category/9/xlings
- xim包索引主仓库: https://github.com/d2learn/xim-pkgindex
