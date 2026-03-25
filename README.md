中文说明

Copilot CLI 代理安装包

目录结构
- macos-linux/install-copilot-proxy.sh
- windows/install-copilot-proxy.cmd
- windows/install-copilot-proxy.ps1

推荐用法

macOS / Linux
1. 打开终端。
2. 可使用 bash 或 zsh 执行：
   bash ./macos-linux/install-copilot-proxy.sh
   zsh ./macos-linux/install-copilot-proxy.sh
3. 按提示完成安装。

Windows（适用于通过 npm 安装的 Copilot CLI）
1. 打开 PowerShell 或 Command Prompt（cmd）。
2. 统一运行：
   .\windows\install-copilot-proxy.cmd
3. 按提示完成安装。

安装脚本会做什么
- 先让用户选择语言：中文或英文
- 询问是否继续安装
- 提示输入代理地址
- 如果发现已有 Copilot 配置文件，提供：
  1) 覆盖
  2) 备份后覆盖
  3) 取消
- 配置：
  - `copilot` 默认通过代理启动
  - `copilot-noproxy` 以直连方式启动
- Windows 安装器会保留原始的 `copilot.cmd` 为备份，并把 npm 生成的 `copilot.ps1` 让开，这样 PowerShell 也会走同一套 `.cmd` 包装器
- 安装一次后，在 PowerShell 和 cmd 中执行 `copilot` / `copilot-noproxy` 都会生效

说明
- macOS/Linux 统一使用 `.sh` 安装脚本，可通过 `bash` 或 `zsh` 执行。
- 安装脚本会自动识别并配置目标 shell（zsh 或 bash）。
- Windows 统一推荐运行 `.cmd` 安装器；即使在 PowerShell 中执行它，最终配置的也是同一套 Windows 包装器。
- 安装完成后，请按脚本提示重新加载 shell/profile。

--------------------------------------------------

English

Copilot CLI proxy installer package

Folder layout
- macos-linux/install-copilot-proxy.sh
- windows/install-copilot-proxy.cmd
- windows/install-copilot-proxy.ps1

Recommended usage

macOS / Linux
1. Open a terminal.
2. Run it with bash or zsh:
   bash ./macos-linux/install-copilot-proxy.sh
   zsh ./macos-linux/install-copilot-proxy.sh
3. Follow the prompts.

Windows (for npm-installed Copilot CLI)
1. Open PowerShell or Command Prompt (cmd).
2. Run:
   .\windows\install-copilot-proxy.cmd
3. Follow the prompts.

What the installers do
- Ask for language: Chinese or English
- Ask whether to continue
- Ask for the proxy URL
- If an existing Copilot helper file is found, offer:
  1) overwrite
  2) backup and overwrite
  3) cancel
- Configure:
  - `copilot` to start with proxy enabled
  - `copilot-noproxy` to start without proxy
- The Windows installer keeps the original `copilot.cmd` as a backup and moves the npm-generated `copilot.ps1` shim out of the way so PowerShell also resolves to the same `.cmd` wrappers
- After one installation, `copilot` and `copilot-noproxy` work the same from both PowerShell and cmd

Notes
- macOS/Linux uses the `.sh` installer as the single entrypoint, and you can run it with `bash` or `zsh`.
- The installer auto-detects and configures the target shell (`zsh` or `bash`).
- On Windows, the recommended entrypoint is the `.cmd` installer. You can launch it from either PowerShell or Command Prompt, and it configures the same Windows wrappers.
- After installation, reload the shell/profile as prompted by the installer.
