#!/usr/bin/env bash

set -euo pipefail

HEALTHCHECK_URL="https://api.business.githubcopilot.com/mcp/readonly"
PROXY_PRESET_1="https://xxx.xxx.xxx:8000"
PROXY_PRESET_2="http://xx.xx.xx.xx:8000"
UI_LANG="en"
TARGET_FILE=""
RC_FILE=""
SOURCE_LINE=""
SHELL_KIND=""

msg() {
  local key="$1"
  local arg="${2-}"

  case "$UI_LANG:$key" in
    zh:header)
      cat <<'EOF'
== Copilot CLI 代理安装脚本 ==
这个脚本会：
  - 自动识别 zsh 或 bash，并创建对应的 Copilot 启动配置
  - 让 `copilot` 默认通过代理启动
  - 让 `copilot-noproxy` 以直连方式启动
  - 在需要时向对应的 shell 配置文件添加 source 语句
  - 支持重复执行，并提供覆盖 / 备份后覆盖 / 取消 三种处理方式
EOF
      ;;
    en:header)
      cat <<'EOF'
== Copilot CLI proxy installer ==
This script will:
  - detect zsh or bash and create the matching Copilot shell helper
  - make `copilot` start with the proxy enabled by default
  - make `copilot-noproxy` start without a proxy
  - add a source line to the matching shell rc file if needed
  - keep the setup repeatable, with overwrite / backup / cancel options
EOF
      ;;
    zh:choose_language) printf '请选择语言 / Please choose a language:\n  1) 中文\n  2) English\n' ;;
    en:choose_language) printf 'Please choose a language / 请选择语言:\n  1) 中文\n  2) English\n' ;;
    zh:enter_language) printf '请输入选项 [1/2]: ' ;;
    en:enter_language) printf 'Enter your choice [1/2]: ' ;;
    zh:invalid_language) printf '无效选项，请输入 1 或 2。\n' ;;
    en:invalid_language) printf 'Invalid choice. Please enter 1 or 2.\n' ;;
    zh:continue_prompt) printf '\n是否继续安装？ [y/n]: ' ;;
    en:continue_prompt) printf '\nContinue with the installation? [y/n]: ' ;;
    zh:cancelled) printf '已取消，未做任何修改。\n' ;;
    en:cancelled) printf 'Cancelled. No changes were made.\n' ;;
    zh:invalid_yes_no) printf '无效输入，请输入 y 或 n。\n' ;;
    en:invalid_yes_no) printf 'Invalid choice. Please enter y or n.\n' ;;
    zh:detected_shell) printf '已识别当前 shell：%s\n' "$arg" ;;
    en:detected_shell) printf 'Detected shell: %s\n' "$arg" ;;
    zh:unsupported_shell) printf '无法自动识别为 zsh 或 bash，请手动选择。\n' ;;
    en:unsupported_shell) printf 'Could not detect zsh or bash automatically. Please choose manually.\n' ;;
    zh:choose_shell) printf '请选择 shell：\n  1) zsh\n  2) bash\n' ;;
    en:choose_shell) printf 'Choose the shell to configure:\n  1) zsh\n  2) bash\n' ;;
    zh:enter_shell_choice) printf '请输入选项 [1/2]: ' ;;
    en:enter_shell_choice) printf 'Enter your choice [1/2]: ' ;;
    zh:invalid_shell_choice) printf '无效选项，请输入 1 或 2。\n' ;;
    en:invalid_shell_choice) printf 'Invalid choice. Please enter 1 or 2.\n' ;;
    zh:target_summary) printf '将写入：%s\n将更新：%s\n' "$TARGET_FILE" "$RC_FILE" ;;
    en:target_summary) printf 'Will write: %s\nWill update: %s\n' "$TARGET_FILE" "$RC_FILE" ;;
    zh:copilot_found) printf '已检测到 Copilot CLI：%s\n' "$arg" ;;
    en:copilot_found) printf 'Detected Copilot CLI: %s\n' "$arg" ;;
    zh:copilot_missing) printf '未检测到 Copilot CLI，请先安装后再运行此脚本。\n' ;;
    en:copilot_missing) printf 'Copilot CLI was not found. Please install it before running this script.\n' ;;
    zh:choose_proxy) printf '请选择代理地址：\n  1) %s\n  2) %s\n  3) 自定义输入\n' "$PROXY_PRESET_1" "$PROXY_PRESET_2" ;;
    en:choose_proxy) printf 'Choose the proxy URL:\n  1) %s\n  2) %s\n  3) Enter a custom value\n' "$PROXY_PRESET_1" "$PROXY_PRESET_2" ;;
    zh:enter_proxy_choice) printf '请输入选项 [1/2/3]: ' ;;
    en:enter_proxy_choice) printf 'Enter your choice [1/2/3]: ' ;;
    zh:invalid_proxy_choice) printf '无效选项，请输入 1、2 或 3。\n' ;;
    en:invalid_proxy_choice) printf 'Invalid choice. Please enter 1, 2, or 3.\n' ;;
    zh:enter_proxy) printf '请输入自定义代理地址（例如：https://proxy.example.com:8000）：' ;;
    en:enter_proxy) printf 'Enter a custom proxy URL (for example: https://proxy.example.com:8000): ' ;;
    zh:proxy_empty) printf '代理地址不能为空。\n' ;;
    en:proxy_empty) printf 'Proxy URL cannot be empty.\n' ;;
    zh:proxy_invalid) printf '代理地址必须以 http:// 或 https:// 开头，且不能包含空格。\n' ;;
    en:proxy_invalid) printf 'Proxy URL must start with http:// or https:// and contain no spaces.\n' ;;
    zh:detected_existing) printf '\n检测到已有文件：%s\n' "$arg" ;;
    en:detected_existing) printf '\nDetected existing file: %s\n' "$arg" ;;
    zh:choose_existing_action) printf '请选择处理方式：\n  1) 覆盖\n  2) 备份后覆盖\n  3) 取消\n' ;;
    en:choose_existing_action) printf 'Choose how to proceed:\n  1) Overwrite\n  2) Overwrite and create a backup\n  3) Cancel\n' ;;
    zh:enter_existing_choice) printf '请输入选项 [1/2/3]: ' ;;
    en:enter_existing_choice) printf 'Enter your choice [1/2/3]: ' ;;
    zh:backup_created) printf '已创建备份：%s\n' "$arg" ;;
    en:backup_created) printf 'Backup created: %s\n' "$arg" ;;
    zh:invalid_existing_choice) printf '无效选项，请输入 1、2 或 3。\n' ;;
    en:invalid_existing_choice) printf 'Invalid choice. Please enter 1, 2, or 3.\n' ;;
    zh:found_source) printf '在 %s 中发现已存在的 source 配置\n' "$arg" ;;
    en:found_source) printf 'Found existing source line in %s\n' "$arg" ;;
    zh:added_source) printf '已向 %s 添加 source 配置\n' "$arg" ;;
    en:added_source) printf 'Added source line to %s\n' "$arg" ;;
    zh:summary)
      cat <<EOF

安装完成。

文件：
  - $TARGET_FILE
  - $RC_FILE

后续操作：
  1. 重新加载 shell：
     source "$RC_FILE"
  2. 通过代理启动 Copilot CLI：
     copilot
  3. 不通过代理启动 Copilot CLI：
     copilot-noproxy
EOF
      ;;
    en:summary)
      cat <<EOF

Installation complete.

Files:
  - $TARGET_FILE
  - $RC_FILE

Next steps:
  1. Reload your shell:
     source "$RC_FILE"
  2. Start Copilot CLI with proxy:
     copilot
  3. Start Copilot CLI without proxy:
     copilot-noproxy
EOF
      ;;
  esac
}

choose_language() {
  local choice

  while true; do
    msg choose_language
    msg enter_language
    IFS= read -r choice

    case "$choice" in
      1) UI_LANG="zh"; return 0 ;;
      2) UI_LANG="en"; return 0 ;;
      *) msg invalid_language >&2 ;;
    esac
  done
}

print_header() {
  msg header
}

ensure_copilot_installed() {
  local copilot_cmd=""

  if copilot_cmd="$(command -v copilot 2>/dev/null)" && [[ -n "$copilot_cmd" ]]; then
    msg copilot_found "$copilot_cmd"
    return 0
  fi

  msg copilot_missing >&2
  exit 1
}

configure_shell_kind() {
  local kind="$1"

  case "$kind" in
    zsh)
      SHELL_KIND="zsh"
      TARGET_FILE="$HOME/.copilot-shell.zsh"
      RC_FILE="$HOME/.zshrc"
      SOURCE_LINE='[[ -f "$HOME/.copilot-shell.zsh" ]] && source "$HOME/.copilot-shell.zsh"'
      ;;
    bash)
      SHELL_KIND="bash"
      TARGET_FILE="$HOME/.copilot-shell.bash"
      if [[ -f "$HOME/.bash_profile" ]]; then
        RC_FILE="$HOME/.bash_profile"
      else
        RC_FILE="$HOME/.bashrc"
      fi
      SOURCE_LINE='[ -f "$HOME/.copilot-shell.bash" ] && source "$HOME/.copilot-shell.bash"'
      ;;
    *)
      return 1
      ;;
  esac
}

choose_shell_kind() {
  local current_shell=""
  local choice

  if [[ -n "${SHELL:-}" ]]; then
    current_shell="$(basename "$SHELL")"
  fi

  case "$current_shell" in
    zsh|bash)
      configure_shell_kind "$current_shell"
      msg detected_shell "$current_shell"
      return 0
      ;;
  esac

  msg unsupported_shell

  while true; do
    msg choose_shell
    msg enter_shell_choice
    IFS= read -r choice

    case "$choice" in
      1) configure_shell_kind zsh; return 0 ;;
      2) configure_shell_kind bash; return 0 ;;
      *) msg invalid_shell_choice >&2 ;;
    esac
  done
}

confirm_continue() {
  local choice

  while true; do
    msg continue_prompt
    IFS= read -r choice

    case "$choice" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No)
        msg cancelled
        exit 0
        ;;
      *)
        msg invalid_yes_no >&2
        ;;
    esac
  done
}

validate_proxy_url() {
  local proxy_url="$1"

  if [[ -z "$proxy_url" ]]; then
    msg proxy_empty >&2
    return 1
  fi

  if [[ ! "$proxy_url" =~ ^https?://[^[:space:]]+$ ]]; then
    msg proxy_invalid >&2
    return 1
  fi

  return 0
}

prompt_proxy_url() {
  local proxy_url choice

  while true; do
    msg choose_proxy
    msg enter_proxy_choice
    IFS= read -r choice

    case "$choice" in
      1)
        REPLY="$PROXY_PRESET_1"
        return 0
        ;;
      2)
        REPLY="$PROXY_PRESET_2"
        return 0
        ;;
      3)
        while true; do
          msg enter_proxy
          IFS= read -r proxy_url
          validate_proxy_url "$proxy_url" || continue
          REPLY="$proxy_url"
          return 0
        done
        ;;
      *)
        msg invalid_proxy_choice >&2
        ;;
    esac
  done
}

handle_existing_target() {
  local timestamp backup_file choice

  [[ -f "$TARGET_FILE" ]] || return 0

  msg detected_existing "$TARGET_FILE"
  msg choose_existing_action

  while true; do
    msg enter_existing_choice
    IFS= read -r choice

    case "$choice" in
      1)
        return 0
        ;;
      2)
        timestamp="$(date +%Y%m%d_%H%M%S)"
        backup_file="${TARGET_FILE}_${timestamp}"
        cp "$TARGET_FILE" "$backup_file"
        msg backup_created "$backup_file"
        return 0
        ;;
      3)
        msg cancelled
        exit 0
        ;;
      *)
        msg invalid_existing_choice >&2
        ;;
    esac
  done
}

write_target_file() {
  local proxy_url="$1"

  cat > "$TARGET_FILE" <<'EOF'
# Copilot CLI launch helpers: proxy on by default, with an explicit no-proxy entrypoint.
export COPILOT_PROXY_URL="__PROXY_URL__"
export COPILOT_HEALTHCHECK_URL="__HEALTHCHECK_URL__"
export COPILOT_UI_LANG="__UI_LANG__"

_copilot_is_interactive_launch() {
  [[ "$1" -eq 0 && -t 1 ]]
}

_copilot_is_zh() {
  [[ "${COPILOT_UI_LANG:-en}" == "zh" ]]
}

_copilot_text() {
  case "$1" in
    enabled) _copilot_is_zh && printf '已开启' || printf 'enabled' ;;
    disabled) _copilot_is_zh && printf '已关闭' || printf 'disabled' ;;
    ok) _copilot_is_zh && printf '成功' || printf 'ok' ;;
    failed) _copilot_is_zh && printf '失败' || printf 'failed' ;;
    running_checks) _copilot_is_zh && printf '[copilot] 正在执行代理检查...' || printf '[copilot] running proxy checks...' ;;
    ping_failed) _copilot_is_zh && printf '(ICMP 被阻止或主机不可达)' || printf '(ICMP blocked or host unreachable)' ;;
    tcp_failed) _copilot_is_zh && printf '(代理端口不可达)' || printf '(proxy port unreachable)' ;;
    cert_untrusted) _copilot_is_zh && printf '(代理证书不受信任)' || printf '(proxy certificate is not trusted)' ;;
    install_root_hint) _copilot_is_zh && printf '[copilot] 提示：请先在这台机器上安装或信任公司根证书，然后再重试' || printf '[copilot] hint: install or trust your company root certificate on this machine, then try again' ;;
    abort_proxy_cert) _copilot_is_zh && printf '[copilot] 已中止：由于代理证书不受信任，未启动 Copilot CLI' || printf '[copilot] abort: not starting Copilot CLI because the proxy certificate is not trusted' ;;
    insecure_revocation) _copilot_is_zh && printf '[copilot] 检查：证书吊销状态无法验证；已用非严格校验确认连通性' || printf '[copilot] check: https certificate revocation could not be verified; connectivity confirmed with insecure verification' ;;
    http_failed) _copilot_is_zh && printf '(无法通过代理访问 Copilot 服务端点)' || printf '(Copilot endpoint not reachable via proxy)' ;;
    abort_healthcheck) _copilot_is_zh && printf '[copilot] 已中止：由于最终代理健康检查失败，未启动 Copilot CLI' || printf '[copilot] abort: not starting Copilot CLI because the final proxy healthcheck failed' ;;
    exec_missing) _copilot_is_zh && printf '[copilot] 错误：未在 PATH 中找到可执行文件' || printf '[copilot] error: executable not found in PATH' ;;
  esac
}

_copilot_show_proxy_mode() {
  local proxy_state="$1"
  local proxy_value="$2"
  local arg_count="$3"
  local color_code="$4"
  _copilot_is_interactive_launch "$arg_count" || return 0

  if _copilot_is_zh; then
    if [[ -n "$proxy_value" ]]; then
      printf '\033[%sm[copilot] 代理：%s (%s)\033[0m\n' "$color_code" "$proxy_state" "$proxy_value"
    else
      printf '\033[%sm[copilot] 代理：%s\033[0m\n' "$color_code" "$proxy_state"
    fi
  else
    if [[ -n "$proxy_value" ]]; then
      printf '\033[%sm[copilot] proxy: %s (%s)\033[0m\n' "$color_code" "$proxy_state" "$proxy_value"
    else
      printf '\033[%sm[copilot] proxy: %s\033[0m\n' "$color_code" "$proxy_state"
    fi
  fi
}

_copilot_print_check_result() {
  local label="$1"
  local ok="$2"
  local detail="$3"
  local status_text color

  status_text="$(_copilot_text "$ok")"
  if [[ "$ok" == "ok" ]]; then
    color='32'
  else
    color='31'
  fi

  printf '\033[%sm[copilot] check: %s -> %s\033[0m %s\n' "$color" "$label" "$status_text" "$detail"
}

_copilot_parse_proxy_url() {
  local proxy_url="$1"
  local proxy_scheme proxy_addr proxy_host proxy_port

  proxy_scheme="${proxy_url%%://*}"
  proxy_addr="${proxy_url#*://}"
  proxy_addr="${proxy_addr%%/*}"
  proxy_host="${proxy_addr%%:*}"
  proxy_port="${proxy_addr##*:}"

  if [[ "$proxy_host" == "$proxy_port" ]]; then
    if [[ "$proxy_scheme" == "https" ]]; then
      proxy_port="443"
    else
      proxy_port="80"
    fi
  fi

  printf '%s %s %s\n' "$proxy_scheme" "$proxy_host" "$proxy_port"
}

_copilot_resolve_command() {
  local copilot_cmd=""

  if copilot_cmd="$(type -P copilot 2>/dev/null)" && [[ -n "$copilot_cmd" ]]; then
    printf '%s\n' "$copilot_cmd"
    return 0
  fi

  if command -v whence >/dev/null 2>&1; then
    copilot_cmd="$(whence -p copilot 2>/dev/null || true)"
    if [[ -n "$copilot_cmd" ]]; then
      printf '%s\n' "$copilot_cmd"
      return 0
    fi
  fi

  return 1
}

_copilot_run_proxy_checks() {
  local proxy_url="$1"
  local arg_count="$2"
  local proxy_scheme proxy_host proxy_port
  local curl_http_code curl_output="" insecure_curl_http_code=""

  _copilot_is_interactive_launch "$arg_count" || return 0
  read -r proxy_scheme proxy_host proxy_port <<< "$(_copilot_parse_proxy_url "$proxy_url")"

  printf '%s\n' "$(_copilot_text running_checks)"

  if ping -c 1 "$proxy_host" >/dev/null 2>&1; then
    _copilot_print_check_result "ping $proxy_host" "ok" ""
  else
    _copilot_print_check_result "ping $proxy_host" "failed" "$(_copilot_text ping_failed)"
  fi

  if nc -z -w 2 "$proxy_host" "$proxy_port" >/dev/null 2>&1; then
    _copilot_print_check_result "tcp $proxy_host:$proxy_port" "ok" ""
  else
    _copilot_print_check_result "tcp $proxy_host:$proxy_port" "failed" "$(_copilot_text tcp_failed)"
  fi

  curl_output="$(
    curl -x "$proxy_url" \
      --connect-timeout 3 \
      --max-time 8 \
      --silent \
      --show-error \
      --output /dev/null \
      --write-out 'HTTP_CODE=%{http_code}' \
      "$COPILOT_HEALTHCHECK_URL" 2>&1
  )"
  curl_http_code="$(printf '%s\n' "$curl_output" | sed -n 's/.*HTTP_CODE=\([0-9][0-9][0-9]\).*/\1/p' | tail -n 1)"

  if [[ -n "$curl_http_code" && "$curl_http_code" != "000" ]]; then
    _copilot_print_check_result "https $COPILOT_HEALTHCHECK_URL" "ok" "(HTTP $curl_http_code via proxy)"
    return 0
  fi

  case "$curl_output" in
    *SEC_E_UNTRUSTED_ROOT*|*"SSL certificate problem"*|*"self signed certificate"*|*"unable to get local issuer certificate"*|*"certificate chain"*|*"不受信任的颁发机构"*)
      _copilot_print_check_result "https $COPILOT_HEALTHCHECK_URL" "failed" "$(_copilot_text cert_untrusted)"
      printf '\033[33m%s\033[0m\n' "$(_copilot_text install_root_hint)"
      printf '\033[31m%s\033[0m\n' "$(_copilot_text abort_proxy_cert)"
      return 1
      ;;
    *CRYPT_E_NO_REVOCATION_CHECK*|*CRYPT_E_REVOCATION_OFFLINE*|*CERT_TRUST_REVOCATION_STATUS_UNKNOWN*|*"unable to get certificate CRL"*|*"吊销功能无法检查"*|*"证书是否吊销"*)
      insecure_curl_http_code="$(
        curl -k -x "$proxy_url" \
          --connect-timeout 3 \
          --max-time 8 \
          --silent \
          --show-error \
          --output /dev/null \
          --write-out '%{http_code}' \
          "$COPILOT_HEALTHCHECK_URL" 2>/dev/null
      )"

      if [[ -n "$insecure_curl_http_code" && "$insecure_curl_http_code" != "000" ]]; then
        printf '\033[33m%s\033[0m\n' "$(_copilot_text insecure_revocation)"
        _copilot_print_check_result "https $COPILOT_HEALTHCHECK_URL" "ok" "(HTTP $insecure_curl_http_code via proxy)"
        return 0
      fi
      ;;
  esac

  _copilot_print_check_result "https $COPILOT_HEALTHCHECK_URL" "failed" "$(_copilot_text http_failed)"
  printf '\033[31m%s\033[0m\n' "$(_copilot_text abort_healthcheck)"
  return 1
}

copilot() {
  local copilot_cmd
  copilot_cmd="$(_copilot_resolve_command)" || {
    printf '\033[31m%s\033[0m\n' "$(_copilot_text exec_missing)"
    return 1
  }

  _copilot_show_proxy_mode "$(_copilot_text enabled)" "$COPILOT_PROXY_URL" $# "36"
  _copilot_run_proxy_checks "$COPILOT_PROXY_URL" $# || return 1
  HTTPS_PROXY="$COPILOT_PROXY_URL" \
  HTTP_PROXY="$COPILOT_PROXY_URL" \
  ALL_PROXY="$COPILOT_PROXY_URL" \
  https_proxy="$COPILOT_PROXY_URL" \
  http_proxy="$COPILOT_PROXY_URL" \
  all_proxy="$COPILOT_PROXY_URL" \
  "$copilot_cmd" "$@"
}

copilot-noproxy() {
  local copilot_cmd
  copilot_cmd="$(_copilot_resolve_command)" || {
    printf '\033[31m%s\033[0m\n' "$(_copilot_text exec_missing)"
    return 1
  }

  _copilot_show_proxy_mode "$(_copilot_text disabled)" "" $# "35"
  env -u HTTPS_PROXY -u HTTP_PROXY -u ALL_PROXY \
    -u https_proxy -u http_proxy -u all_proxy \
    "$copilot_cmd" "$@"
}
EOF

  PROXY_URL="$proxy_url" \
  HEALTHCHECK_URL="$HEALTHCHECK_URL" \
  UI_LANG="$UI_LANG" \
  perl -0pi -e 's/__PROXY_URL__/$ENV{PROXY_URL}/g; s/__HEALTHCHECK_URL__/$ENV{HEALTHCHECK_URL}/g; s/__UI_LANG__/$ENV{UI_LANG}/g;' "$TARGET_FILE"

  chmod 600 "$TARGET_FILE"
}

ensure_rc_source() {
  touch "$RC_FILE"

  if grep -Fqx "$SOURCE_LINE" "$RC_FILE"; then
    msg found_source "$RC_FILE"
    return 0
  fi

  if [[ -s "$RC_FILE" ]]; then
    printf '\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"
  else
    printf '%s\n' "$SOURCE_LINE" >> "$RC_FILE"
  fi

  msg added_source "$RC_FILE"
}

print_summary() {
  msg summary
}

main() {
  local proxy_url

  choose_language
  print_header
  ensure_copilot_installed
  choose_shell_kind
  msg target_summary
  confirm_continue
  prompt_proxy_url
  proxy_url="$REPLY"

  handle_existing_target
  write_target_file "$proxy_url"
  ensure_rc_source
  print_summary
}

main "$@"
