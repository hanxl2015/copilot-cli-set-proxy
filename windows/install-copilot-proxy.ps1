$ErrorActionPreference = 'Stop'

$script:UiLang = 'en'
$script:HealthcheckUrl = 'https://api.business.githubcopilot.com/mcp/readonly'
$script:ProxyPreset1 = 'https://xxx.xxx.xxx:8000'
$script:ProxyPreset2 = 'http://xx.xx.xx.xx:8000'
$script:WrapperMarker = 'COPILOT_PROXY_WRAPPER_MARKER'
$script:CopilotCmdPath = $null
$script:InstallDir = $null
$script:WrapperPath = $null
$script:NoProxyPath = $null
$script:OriginalBackupPath = $null
$script:CheckScriptPath = $null

function Show-Message {
    param(
        [Parameter(Mandatory)]
        [string] $Key,
        [string] $Value
    )

    switch ("$script:UiLang|$Key") {
        'zh|Header' {
            @'
== Copilot CLI Windows 代理安装脚本 ==
这个脚本会：
  - 为 Windows 中的 Copilot CLI 配置代理包装器
  - 让 `copilot` 在 PowerShell 和 cmd 中默认通过代理启动
  - 让 `copilot-noproxy` 在 PowerShell 和 cmd 中以直连方式启动
  - 为 npm 安装的 `copilot.cmd` 保留原始启动文件备份
  - 支持重复执行，并提供覆盖 / 备份后覆盖 / 取消 三种处理方式
'@ | Write-Host
        }
        'en|Header' {
            @'
== Copilot CLI Windows proxy installer ==
This script will:
  - configure proxy wrappers for Copilot CLI on Windows
  - make `copilot` start with the proxy enabled by default in both PowerShell and cmd
  - make `copilot-noproxy` start without a proxy in both PowerShell and cmd
  - keep a backup of the original npm-installed `copilot.cmd`
  - keep the setup repeatable, with overwrite / backup / cancel options
'@ | Write-Host
        }
        'zh|ChooseLanguage' { Write-Host "请选择语言 / Please choose a language:`n  1) 中文`n  2) English" }
        'en|ChooseLanguage' { Write-Host "Please choose a language / 请选择语言:`n  1) 中文`n  2) English" }
        'zh|EnterLanguage' { Write-Host -NoNewline '请输入选项 [1/2]: ' }
        'en|EnterLanguage' { Write-Host -NoNewline 'Enter your choice [1/2]: ' }
        'zh|InvalidLanguage' { Write-Host '无效选项，请输入 1 或 2。' -ForegroundColor Red }
        'en|InvalidLanguage' { Write-Host 'Invalid choice. Please enter 1 or 2.' -ForegroundColor Red }
        'zh|CopilotFound' { Write-Host "已检测到 Windows 版 Copilot CLI：$Value" }
        'en|CopilotFound' { Write-Host "Detected Windows Copilot CLI: $Value" }
        'zh|CopilotMissing' {
            Write-Host '未检测到 copilot.cmd。这个安装器面向 Windows 上通过 npm 安装的 Copilot CLI。' -ForegroundColor Red
            Write-Host '可先执行安装命令：npm install -g @github/copilot' -ForegroundColor Yellow
        }
        'en|CopilotMissing' {
            Write-Host 'copilot.cmd was not found. This installer is intended for npm-installed Copilot CLI on Windows.' -ForegroundColor Red
            Write-Host 'Install it first with: npm install -g @github/copilot' -ForegroundColor Yellow
        }
        'zh|TargetSummary' { Write-Host "将更新：$script:WrapperPath`n将创建：$script:NoProxyPath`n将备份原始文件到：$script:OriginalBackupPath" }
        'en|TargetSummary' { Write-Host "Will update: $script:WrapperPath`nWill create: $script:NoProxyPath`nWill keep the original file at: $script:OriginalBackupPath" }
        'zh|ContinuePrompt' { Write-Host -NoNewline "`n是否继续安装？ [y/n]: " }
        'en|ContinuePrompt' { Write-Host -NoNewline "`nContinue with the installation? [y/n]: " }
        'zh|Cancelled' { Write-Host '已取消，未做任何修改。' }
        'en|Cancelled' { Write-Host 'Cancelled. No changes were made.' }
        'zh|InvalidYesNo' { Write-Host '无效输入，请输入 y 或 n。' -ForegroundColor Red }
        'en|InvalidYesNo' { Write-Host 'Invalid choice. Please enter y or n.' -ForegroundColor Red }
        'zh|ChooseProxy' { Write-Host "请选择代理地址:`n  1) $script:ProxyPreset1`n  2) $script:ProxyPreset2`n  3) 自定义输入" }
        'en|ChooseProxy' { Write-Host "Choose the proxy URL:`n  1) $script:ProxyPreset1`n  2) $script:ProxyPreset2`n  3) Enter a custom value" }
        'zh|EnterProxyChoice' { Write-Host -NoNewline '请输入选项 [1/2/3]: ' }
        'en|EnterProxyChoice' { Write-Host -NoNewline 'Enter your choice [1/2/3]: ' }
        'zh|InvalidProxyChoice' { Write-Host '无效选项，请输入 1、2 或 3。' -ForegroundColor Red }
        'en|InvalidProxyChoice' { Write-Host 'Invalid choice. Please enter 1, 2, or 3.' -ForegroundColor Red }
        'zh|EnterProxy' { Write-Host -NoNewline '请输入自定义代理地址（例如：https://proxy.example.com:8000）：' }
        'en|EnterProxy' { Write-Host -NoNewline 'Enter a custom proxy URL (for example: https://proxy.example.com:8000): ' }
        'zh|ProxyEmpty' { Write-Host '代理地址不能为空。' -ForegroundColor Red }
        'en|ProxyEmpty' { Write-Host 'Proxy URL cannot be empty.' -ForegroundColor Red }
        'zh|ProxyInvalid' { Write-Host '代理地址必须以 http:// 或 https:// 开头，且不能包含空格。' -ForegroundColor Red }
        'en|ProxyInvalid' { Write-Host 'Proxy URL must start with http:// or https:// and contain no spaces.' -ForegroundColor Red }
        'zh|DetectedExisting' { Write-Host "`n检测到已有 CMD 代理包装器：$Value" }
        'en|DetectedExisting' { Write-Host "`nDetected an existing CMD proxy wrapper: $Value" }
        'zh|ChooseExistingAction' { Write-Host "请选择处理方式：`n  1) 覆盖`n  2) 备份后覆盖`n  3) 取消" }
        'en|ChooseExistingAction' { Write-Host "Choose how to proceed:`n  1) Overwrite`n  2) Overwrite and create backups`n  3) Cancel" }
        'zh|EnterExistingChoice' { Write-Host -NoNewline '请输入选项 [1/2/3]: ' }
        'en|EnterExistingChoice' { Write-Host -NoNewline 'Enter your choice [1/2/3]: ' }
        'zh|BackupCreated' { Write-Host "已创建备份：$Value" }
        'en|BackupCreated' { Write-Host "Backup created: $Value" }
        'zh|InvalidExistingChoice' { Write-Host '无效选项，请输入 1、2 或 3。' -ForegroundColor Red }
        'en|InvalidExistingChoice' { Write-Host 'Invalid choice. Please enter 1, 2, or 3.' -ForegroundColor Red }
        'zh|Summary' {
            @"

安装完成。

文件：
  - $script:WrapperPath
  - $script:NoProxyPath
  - $script:CheckScriptPath
  - $script:OriginalBackupPath

后续操作：
  1. 打开新的 PowerShell 或 cmd 窗口，或在当前窗口重新执行命令。
  2. 通过代理启动 Copilot CLI：
     copilot
  3. 不通过代理启动 Copilot CLI：
     copilot-noproxy
"@ | Write-Host
        }
        'en|Summary' {
            @"

Installation complete.

Files:
  - $script:WrapperPath
  - $script:NoProxyPath
  - $script:CheckScriptPath
  - $script:OriginalBackupPath

Next steps:
  1. Open a new PowerShell or cmd window, or rerun the commands in the current one.
  2. Start Copilot CLI with proxy:
     copilot
  3. Start Copilot CLI without proxy:
     copilot-noproxy
"@ | Write-Host
        }
    }
}

function Choose-Language {
    while ($true) {
        Show-Message ChooseLanguage
        Show-Message EnterLanguage
        $choice = Read-Host

        switch ($choice) {
            '1' { $script:UiLang = 'zh'; return }
            '2' { $script:UiLang = 'en'; return }
            default { Show-Message InvalidLanguage }
        }
    }
}

function Ensure-CopilotCmdInstalled {
    $command = Get-Command copilot.cmd -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq 'Application' } |
        Select-Object -First 1

    if (-not $command) {
        $command = Get-Command copilot -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandType -eq 'Application' -and $_.Source -like '*.cmd' } |
            Select-Object -First 1
    }

    if (-not $command) {
        Show-Message CopilotMissing
        exit 1
    }

    $script:CopilotCmdPath = $command.Source
    $script:InstallDir = Split-Path -Parent $script:CopilotCmdPath
    $script:WrapperPath = $script:CopilotCmdPath
    $script:NoProxyPath = Join-Path $script:InstallDir 'copilot-noproxy.cmd'
    $script:OriginalBackupPath = Join-Path $script:InstallDir 'copilot-original.cmd'
    $script:CheckScriptPath = Join-Path $script:InstallDir 'copilot-proxy-check.ps1'
    $script:PowerShellShimPath = Join-Path $script:InstallDir 'copilot.ps1'
    $script:PowerShellShimBackupPath = Join-Path $script:InstallDir 'copilot-original.ps1'
    $script:NoProxyPowerShellShimPath = Join-Path $script:InstallDir 'copilot-noproxy.ps1'
    $script:NoProxyPowerShellShimBackupPath = Join-Path $script:InstallDir 'copilot-noproxy-original.ps1'

    Show-Message CopilotFound $script:CopilotCmdPath
}

function Confirm-Continue {
    while ($true) {
        Show-Message ContinuePrompt
        $choice = Read-Host

        switch -Regex ($choice) {
            '^(?i:y|yes)$' { return }
            '^(?i:n|no)$' {
                Show-Message Cancelled
                exit 0
            }
            default { Show-Message InvalidYesNo }
        }
    }
}

function Test-ProxyUrl {
    param(
        [Parameter(Mandatory)]
        [string] $ProxyUrl
    )

    if ([string]::IsNullOrWhiteSpace($ProxyUrl)) {
        Show-Message ProxyEmpty
        return $false
    }

    if ($ProxyUrl -notmatch '^https?://\S+$') {
        Show-Message ProxyInvalid
        return $false
    }

    try {
        $uri = [Uri] $ProxyUrl
        if ($uri.Scheme -notin @('http', 'https')) {
            throw 'invalid'
        }
        return $true
    }
    catch {
        Show-Message ProxyInvalid
        return $false
    }
}

function Prompt-ProxyUrl {
    while ($true) {
        Show-Message ChooseProxy
        Show-Message EnterProxyChoice
        $choice = Read-Host

        switch ($choice) {
            '1' { return $script:ProxyPreset1 }
            '2' { return $script:ProxyPreset2 }
            '3' {
                while ($true) {
                    Show-Message EnterProxy
                    $proxyUrl = Read-Host
                    if (Test-ProxyUrl -ProxyUrl $proxyUrl) {
                        return $proxyUrl
                    }
                }
            }
            default { Show-Message InvalidProxyChoice }
        }
    }
}

function Test-IsWrapperInstalled {
    if (Test-Path -LiteralPath $script:WrapperPath) {
        $content = Get-Content -LiteralPath $script:WrapperPath -Raw -ErrorAction SilentlyContinue
        if ($content -match $script:WrapperMarker) {
            return $true
        }
    }

    return (Test-Path -LiteralPath $script:OriginalBackupPath) -or
        (Test-Path -LiteralPath $script:PowerShellShimBackupPath) -or
        (Test-Path -LiteralPath $script:NoProxyPowerShellShimBackupPath) -or
        (Test-Path -LiteralPath $script:NoProxyPath) -or
        (Test-Path -LiteralPath $script:CheckScriptPath)
}

function Backup-IfExists {
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $Timestamp
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $backupPath = '{0}_{1}' -f $Path, $Timestamp
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    Show-Message BackupCreated $backupPath
}

function Handle-ExistingInstallation {
    if (-not (Test-IsWrapperInstalled)) {
        return
    }

    Show-Message DetectedExisting $script:WrapperPath
    Show-Message ChooseExistingAction

    while ($true) {
        Show-Message EnterExistingChoice
        $choice = Read-Host

        switch ($choice) {
            '1' { return }
            '2' {
                $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                Backup-IfExists -Path $script:WrapperPath -Timestamp $timestamp
                Backup-IfExists -Path $script:NoProxyPath -Timestamp $timestamp
                Backup-IfExists -Path $script:CheckScriptPath -Timestamp $timestamp
                Backup-IfExists -Path $script:OriginalBackupPath -Timestamp $timestamp
                Backup-IfExists -Path $script:PowerShellShimPath -Timestamp $timestamp
                Backup-IfExists -Path $script:PowerShellShimBackupPath -Timestamp $timestamp
                Backup-IfExists -Path $script:NoProxyPowerShellShimPath -Timestamp $timestamp
                Backup-IfExists -Path $script:NoProxyPowerShellShimBackupPath -Timestamp $timestamp
                return
            }
            '3' {
                Show-Message Cancelled
                exit 0
            }
            default { Show-Message InvalidExistingChoice }
        }
    }
}

function Ensure-OriginalBackup {
    if (Test-Path -LiteralPath $script:OriginalBackupPath) {
        return
    }

    Move-Item -LiteralPath $script:WrapperPath -Destination $script:OriginalBackupPath -Force
}

function Ensure-PowerShellShimBackups {
    if ((Test-Path -LiteralPath $script:PowerShellShimPath) -and -not (Test-Path -LiteralPath $script:PowerShellShimBackupPath)) {
        Move-Item -LiteralPath $script:PowerShellShimPath -Destination $script:PowerShellShimBackupPath -Force
    }

    if (Test-Path -LiteralPath $script:PowerShellShimPath) {
        Remove-Item -LiteralPath $script:PowerShellShimPath -Force
    }

    if ((Test-Path -LiteralPath $script:NoProxyPowerShellShimPath) -and -not (Test-Path -LiteralPath $script:NoProxyPowerShellShimBackupPath)) {
        Move-Item -LiteralPath $script:NoProxyPowerShellShimPath -Destination $script:NoProxyPowerShellShimBackupPath -Force
    }

    if (Test-Path -LiteralPath $script:NoProxyPowerShellShimPath) {
        Remove-Item -LiteralPath $script:NoProxyPowerShellShimPath -Force
    }
}

function Get-CheckScriptContent {
    $content = @'
param(
    [ValidateSet('proxy', 'noproxy')]
    [string] $Mode = 'proxy',
    [string] $ProxyUrl,
    [string] $HealthcheckUrl
)

$UiLang = '__UI_LANG__'

function Get-Text {
    param(
        [Parameter(Mandatory)]
        [string] $Key
    )

    switch ("$UiLang|$Key") {
        'zh|ProxyEnabled' { return '已开启' }
        'en|ProxyEnabled' { return 'enabled' }
        'zh|ProxyDisabled' { return '已关闭' }
        'en|ProxyDisabled' { return 'disabled' }
        'zh|RunningChecks' { return '[copilot] 正在执行代理检查...' }
        'en|RunningChecks' { return '[copilot] running proxy checks...' }
        'zh|Ok' { return '成功' }
        'en|Ok' { return 'ok' }
        'zh|Failed' { return '失败' }
        'en|Failed' { return 'failed' }
        'zh|PingFailed' { return '(ICMP 被阻止或主机不可达)' }
        'en|PingFailed' { return '(ICMP blocked or host unreachable)' }
        'zh|TcpFailed' { return '(代理端口不可达)' }
        'en|TcpFailed' { return '(proxy port unreachable)' }
        'zh|ProxyAuthFailed' { return '(代理需要身份验证，HTTP {0})' }
        'en|ProxyAuthFailed' { return '(proxy authentication required, HTTP {0})' }
        'zh|ProxyCertUntrusted' { return '(Windows 不信任该代理证书链)' }
        'en|ProxyCertUntrusted' { return '(Windows does not trust the proxy certificate chain)' }
        'zh|InstallRootHint' { return '[copilot] 提示：请先在这台 Windows 机器上安装或信任公司根证书，然后再重试' }
        'en|InstallRootHint' { return '[copilot] hint: install or trust your company root certificate on this Windows machine, then try again' }
        'zh|AbortProxyCert' { return '[copilot] 已中止：由于代理证书不受信任，未启动 Copilot CLI' }
        'en|AbortProxyCert' { return '[copilot] abort: not starting Copilot CLI because the proxy certificate is not trusted' }
        'zh|InsecureRevocation' { return '[copilot] 检查：证书吊销状态无法验证；已用非严格校验确认连通性' }
        'en|InsecureRevocation' { return '[copilot] check: https certificate revocation could not be verified; connectivity confirmed with insecure verification' }
        'zh|HttpFailed' { return '(无法通过代理访问 Copilot 服务端点)' }
        'en|HttpFailed' { return '(Copilot endpoint not reachable via proxy)' }
        'zh|AbortHealthcheck' { return '[copilot] 已中止：由于最终代理健康检查失败，未启动 Copilot CLI' }
        'en|AbortHealthcheck' { return '[copilot] abort: not starting Copilot CLI because the final proxy healthcheck failed' }
        default { return $Key }
    }
}

function Write-Mode {
    param(
        [Parameter(Mandatory)]
        [string] $ProxyState,
        [string] $ProxyValue
    )

    if ($UiLang -eq 'zh') {
        if ($ProxyValue) {
            Write-Host "[copilot] 代理：$ProxyState ($ProxyValue)" -ForegroundColor Cyan
        }
        else {
            Write-Host "[copilot] 代理：$ProxyState" -ForegroundColor Magenta
        }
        return
    }

    if ($ProxyValue) {
        Write-Host "[copilot] proxy: $ProxyState ($ProxyValue)" -ForegroundColor Cyan
    }
    else {
        Write-Host "[copilot] proxy: $ProxyState" -ForegroundColor Magenta
    }
}

function Write-CheckResult {
    param(
        [Parameter(Mandatory)]
        [string] $Label,
        [Parameter(Mandatory)]
        [bool] $Passed,
        [string] $Detail = ''
    )

    $statusText = if ($Passed) { Get-Text Ok } else { Get-Text Failed }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host "[copilot] check: $Label -> $statusText $Detail".TrimEnd() -ForegroundColor $color
}

if ($Mode -eq 'noproxy') {
    Write-Mode -ProxyState (Get-Text ProxyDisabled)
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProxyUrl) -or [string]::IsNullOrWhiteSpace($HealthcheckUrl)) {
    throw 'ProxyUrl and HealthcheckUrl are required in proxy mode.'
}

$ErrorActionPreference = 'Stop'
$uri = [Uri] $ProxyUrl
$port = if ($uri.Port -gt 0) { $uri.Port } elseif ($uri.Scheme -eq 'https') { 443 } else { 80 }
$curlPath = Get-Command curl.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue

Write-Mode -ProxyState (Get-Text ProxyEnabled) -ProxyValue $ProxyUrl
Write-Host (Get-Text RunningChecks)

try {
    $pingOk = Test-Connection -TargetName $uri.Host -Count 1 -Quiet -ErrorAction Stop
}
catch {
    $pingOk = $false
}

if ($pingOk) {
    Write-CheckResult -Label "ping $($uri.Host)" -Passed $true
}
else {
    Write-CheckResult -Label "ping $($uri.Host)" -Passed $false -Detail (Get-Text PingFailed)
}

$tcpClient = [System.Net.Sockets.TcpClient]::new()
try {
    $async = $tcpClient.BeginConnect($uri.Host, $port, $null, $null)
    $tcpOk = $async.AsyncWaitHandle.WaitOne(2000, $false)
    if ($tcpOk) {
        $tcpClient.EndConnect($async)
    }
}
catch {
    $tcpOk = $false
}
finally {
    $tcpClient.Dispose()
}

if ($tcpOk) {
    Write-CheckResult -Label "tcp $($uri.Host):$port" -Passed $true
}
else {
    Write-CheckResult -Label "tcp $($uri.Host):$port" -Passed $false -Detail (Get-Text TcpFailed)
}

$response = $null

if ($curlPath) {
    $httpCode = ''
    $curlText = ''
    try {
        $curlOutput = & $curlPath -x $ProxyUrl --connect-timeout 3 --max-time 8 --silent --show-error --output NUL --write-out 'HTTP_CODE=%{http_code}' $HealthcheckUrl 2>&1
        $curlText = ($curlOutput | ForEach-Object { "$_" }) -join "`n"
        if ($curlText -match 'HTTP_CODE=(\d{3})') {
            $httpCode = $Matches[1]
        }
    }
    catch {
        $curlText = $_ | Out-String
    }

    if (-not [string]::IsNullOrWhiteSpace($httpCode) -and $httpCode -ne '000') {
        if ($httpCode -eq '407') {
            Write-CheckResult -Label "https $HealthcheckUrl" -Passed $false -Detail ((Get-Text ProxyAuthFailed) -f $httpCode)
            Write-Host (Get-Text AbortHealthcheck) -ForegroundColor Red
            exit 1
        }

        Write-CheckResult -Label "https $HealthcheckUrl" -Passed $true -Detail "(HTTP $httpCode via proxy)"
        exit 0
    }

    if ($curlText -match 'SEC_E_UNTRUSTED_ROOT|CRYPT_E_NO_REVOCATION_CHECK|CRYPT_E_REVOCATION_OFFLINE|CERT_TRUST_REVOCATION_STATUS_UNKNOWN|schannel|SSL certificate problem|certificate chain|不受信任的颁发机构|吊销功能无法检查|证书是否吊销') {
        $needsTrustedRoot = $curlText -match 'SEC_E_UNTRUSTED_ROOT|SSL certificate problem|certificate chain|不受信任的颁发机构'
        if ($needsTrustedRoot) {
            Write-CheckResult -Label "https $HealthcheckUrl" -Passed $false -Detail (Get-Text ProxyCertUntrusted)
            Write-Host (Get-Text InstallRootHint) -ForegroundColor Yellow
            Write-Host (Get-Text AbortProxyCert) -ForegroundColor Red
            exit 1
        }

        $insecureHttpCode = ''
        try {
            $curlOutput = & $curlPath -k -x $ProxyUrl --connect-timeout 3 --max-time 8 --silent --show-error --output NUL --write-out 'HTTP_CODE=%{http_code}' $HealthcheckUrl 2>&1
            $curlText = ($curlOutput | ForEach-Object { "$_" }) -join "`n"
            if ($curlText -match 'HTTP_CODE=(\d{3})') {
                $insecureHttpCode = $Matches[1]
            }
        }
        catch {
            $insecureHttpCode = ''
        }

        if (-not [string]::IsNullOrWhiteSpace($insecureHttpCode) -and $insecureHttpCode -ne '000') {
            Write-Host (Get-Text InsecureRevocation) -ForegroundColor Yellow
            Write-CheckResult -Label "https $HealthcheckUrl" -Passed $true -Detail "(HTTP $insecureHttpCode via proxy)"
            exit 0
        }
    }
}

try {
    if ([Enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'Tls12') {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    }

    $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($HealthcheckUrl)
    $request.Proxy = [System.Net.WebProxy]::new($ProxyUrl)
    $request.Method = 'GET'
    $request.Timeout = 8000
    $request.ReadWriteTimeout = 8000
    $response = [System.Net.HttpWebResponse] $request.GetResponse()
    Write-CheckResult -Label "https $HealthcheckUrl" -Passed $true -Detail "(HTTP $([int] $response.StatusCode) via proxy)"
    exit 0
}
catch {
    $response = $_.Exception.Response -as [System.Net.HttpWebResponse]

    if ($null -ne $response) {
        $statusCode = [int] $response.StatusCode
        if ($statusCode -eq 407) {
            Write-CheckResult -Label "https $HealthcheckUrl" -Passed $false -Detail ((Get-Text ProxyAuthFailed) -f $statusCode)
            Write-Host (Get-Text AbortHealthcheck) -ForegroundColor Red
            exit 1
        }

        Write-CheckResult -Label "https $HealthcheckUrl" -Passed $true -Detail "(HTTP $statusCode via proxy)"
        exit 0
    }

    Write-CheckResult -Label "https $HealthcheckUrl" -Passed $false -Detail (Get-Text HttpFailed)
    Write-Host (Get-Text AbortHealthcheck) -ForegroundColor Red
    exit 1
}
finally {
    if ($null -ne $response) { $response.Dispose() }
}
'@

    return $content.Replace('__UI_LANG__', $script:UiLang)
}

function Get-ProxyWrapperContent {
    param(
        [Parameter(Mandatory)]
        [string] $ProxyUrl
    )

    $content = @'
@echo off
setlocal
REM COPILOT_PROXY_WRAPPER_MARKER
set "COPILOT_PROXY_URL=__PROXY_URL__"
set "COPILOT_HEALTHCHECK_URL=__HEALTHCHECK_URL__"
set "COPILOT_ORIGINAL_CMD=%~dp0copilot-original.cmd"
set "COPILOT_CHECK_SCRIPT=%~dp0copilot-proxy-check.ps1"

if not exist "%COPILOT_ORIGINAL_CMD%" (
  echo [copilot] error: original cmd launcher not found
  exit /b 1
)

if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%COPILOT_CHECK_SCRIPT%" -Mode proxy -ProxyUrl "%COPILOT_PROXY_URL%" -HealthcheckUrl "%COPILOT_HEALTHCHECK_URL%"
  if errorlevel 1 exit /b 1
)

set "HTTPS_PROXY=%COPILOT_PROXY_URL%"
set "HTTP_PROXY=%COPILOT_PROXY_URL%"
set "ALL_PROXY=%COPILOT_PROXY_URL%"
set "https_proxy=%COPILOT_PROXY_URL%"
set "http_proxy=%COPILOT_PROXY_URL%"
set "all_proxy=%COPILOT_PROXY_URL%"

call "%COPILOT_ORIGINAL_CMD%" %*
exit /b %ERRORLEVEL%
'@

    $content = $content.Replace('__PROXY_URL__', $ProxyUrl)
    $content = $content.Replace('__HEALTHCHECK_URL__', $script:HealthcheckUrl)
    return $content
}

function Get-NoProxyWrapperContent {
    @'
@echo off
setlocal
REM COPILOT_PROXY_WRAPPER_MARKER
set "COPILOT_ORIGINAL_CMD=%~dp0copilot-original.cmd"
set "COPILOT_CHECK_SCRIPT=%~dp0copilot-proxy-check.ps1"

if not exist "%COPILOT_ORIGINAL_CMD%" (
  echo [copilot] error: original cmd launcher not found
  exit /b 1
)

if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%COPILOT_CHECK_SCRIPT%" -Mode noproxy
)

set "HTTPS_PROXY="
set "HTTP_PROXY="
set "ALL_PROXY="
set "https_proxy="
set "http_proxy="
set "all_proxy="

call "%COPILOT_ORIGINAL_CMD%" %*
exit /b %ERRORLEVEL%
'@
}

function Write-InstallerFiles {
    param(
        [Parameter(Mandatory)]
        [string] $ProxyUrl
    )

    Set-Content -LiteralPath $script:CheckScriptPath -Value (Get-CheckScriptContent) -Encoding UTF8
    Set-Content -LiteralPath $script:WrapperPath -Value (Get-ProxyWrapperContent -ProxyUrl $ProxyUrl) -Encoding ASCII
    Set-Content -LiteralPath $script:NoProxyPath -Value (Get-NoProxyWrapperContent) -Encoding ASCII
}

function Show-Summary {
    Show-Message Summary
}

function Main {
    Choose-Language
    Show-Message Header
    Ensure-CopilotCmdInstalled
    Show-Message TargetSummary
    Confirm-Continue
    $proxyUrl = Prompt-ProxyUrl
    Handle-ExistingInstallation
    Ensure-OriginalBackup
    Ensure-PowerShellShimBackups
    Write-InstallerFiles -ProxyUrl $proxyUrl
    Show-Summary
}

Main
