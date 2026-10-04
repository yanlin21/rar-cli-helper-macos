# RAR CLI Helper for macOS

RARLAB `rar` 与 `unrar` 命令行工具的交互式 macOS 菜单。支持：

- 将文件或文件夹压缩为 `.rar`
- 解压 RAR（默认跳过已有同名文件）
- 查看压缩包内容
- 测试压缩包完整性
- 清理所选目录中的 `.DS_Store`、`._*` 和 `__MACOSX` 元数据

本项目与 RARLAB/WinRAR 无隶属或官方合作关系，不包含也不重新分发其二进制程序。

## Requirements

- macOS
- 从 [RARLAB](https://www.rarlab.com/download.htm) 获取的 `rar` 与 `unrar`

确保两个程序在 `PATH` 中，然后运行：

```bash
chmod +x rar-cli-helper.command
./rar-cli-helper.command
```

也可以明确指定可执行文件：

```bash
RAR_BIN=/path/to/rar UNRAR_BIN=/path/to/unrar ./rar-cli-helper.command
```

## Safety notes

- 覆盖已有压缩包前会要求确认。
- 解压时默认跳过已有同名文件。
- 元数据清理仅删除 `.DS_Store`、`._*` 和名为 `__MACOSX` 的目录。
- 压缩前清理元数据仅作用于用户明确选择的普通目录，不跟随目录符号链接。

## License

本启动脚本使用 MIT License。RARLAB 工具受其自身许可证约束。
