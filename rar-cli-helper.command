#!/bin/zsh

# Interactive macOS helper for RARLAB's rar and unrar command-line tools.

emulate -L zsh
setopt NO_NOMATCH

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

RAR_BIN="${RAR_BIN:-$(command -v rar 2>/dev/null || true)}"
UNRAR_BIN="${UNRAR_BIN:-$(command -v unrar 2>/dev/null || true)}"

clear

pause_for_enter() {
  echo
  echo "按回车键返回菜单..."
  read -r
}

clean_path() {
  local raw="$1"
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  print -r -- "${(Q)raw}"
}

read_path() {
  local prompt="$1"
  local raw_path
  echo "$prompt"
  echo "可以直接把文件或文件夹拖到这个窗口里，然后按回车。"
  printf "> "
  read -r raw_path
  clean_path "$raw_path"
}

check_tools() {
  if [[ -z "$RAR_BIN" || ! -x "$RAR_BIN" ]]; then
    echo "找不到 rar。请从 RARLAB 下载并把 rar 放入 PATH。"
    return 1
  fi

  if [[ -z "$UNRAR_BIN" || ! -x "$UNRAR_BIN" ]]; then
    echo "找不到 unrar。请从 RARLAB 下载并把 unrar 放入 PATH。"
    return 1
  fi

  return 0
}

clean_mac_junk_dir() {
  local dir="$1"
  local item
  integer count=0

  [[ -d "$dir" && ! -L "$dir" ]] || return 0

  while IFS= read -r -d '' item; do
    if [[ -d "$item" && ! -L "$item" ]]; then
      rm -rf -- "$item"
    else
      rm -f -- "$item"
    fi
    (( count++ ))
  done < <(find "$dir" \( -type d -name "__MACOSX" -print0 -prune \) -o \( -type f \( -name ".DS_Store" -o -name "._*" \) -print0 \))

  if (( count > 0 )); then
    echo "已清理 $count 个 macOS 隐藏垃圾文件/文件夹。"
  else
    echo "没有发现需要清理的 macOS 隐藏垃圾文件。"
  fi
}

clean_mac_junk_only() {
  local target
  target="$(read_path "请选择要清理的文件夹：")"
  if [[ ! -d "$target" || -L "$target" ]]; then
    echo "这不是可处理的普通文件夹：$target"
    pause_for_enter
    return
  fi

  echo
  clean_mac_junk_dir "$target"
  pause_for_enter
}

make_archive() {
  local target archive default_archive base parent overwrite

  if [[ -n "${1:-}" ]]; then
    target="$1"
  else
    target="$(read_path "请选择要压缩的文件或文件夹：")"
  fi

  if [[ ! -e "$target" ]]; then
    echo "这个路径不存在：$target"
    pause_for_enter
    return
  fi

  base="$(basename "$target")"
  parent="$(dirname "$target")"
  default_archive="$HOME/Desktop/${base}.rar"

  [[ -d "$target" && ! -L "$target" ]] && clean_mac_junk_dir "$target"

  echo
  echo "压缩包保存位置："
  echo "直接回车使用默认位置：$default_archive"
  printf "> "
  read -r archive
  archive="$(clean_path "$archive")"
  [[ -z "$archive" ]] && archive="$default_archive"

  if [[ -e "$archive" ]]; then
    echo
    echo "压缩包已存在：$archive"
    printf "输入 y 覆盖它，输入其他内容取消："
    read -r overwrite
    case "$overwrite" in
      y|Y) rm -f -- "$archive" ;;
      *)
        echo "已取消。"
        pause_for_enter
        return
        ;;
    esac
  fi

  echo
  echo "开始压缩..."
  if (cd "$parent" && "$RAR_BIN" a -r "$archive" "$base" '-x*.DS_Store' '-x*._*' '-x*__MACOSX*'); then
    echo
    echo "完成：$archive"
  else
    echo
    echo "压缩失败。"
  fi
  pause_for_enter
}

extract_archive() {
  local archive out_dir default_dir name

  if [[ -n "${1:-}" ]]; then
    archive="$1"
  else
    archive="$(read_path "请选择要解压的 RAR 压缩包：")"
  fi

  if [[ ! -f "$archive" ]]; then
    echo "这个压缩包不存在：$archive"
    pause_for_enter
    return
  fi

  name="$(basename "$archive")"
  default_dir="$HOME/Desktop/${name%.*}"

  echo
  echo "解压到哪个文件夹？"
  echo "直接回车使用默认位置：$default_dir"
  printf "> "
  read -r out_dir
  out_dir="$(clean_path "$out_dir")"
  [[ -z "$out_dir" ]] && out_dir="$default_dir"
  mkdir -p "$out_dir"

  echo
  echo "开始解压（已有同名文件将被跳过）..."
  if "$UNRAR_BIN" x -o- "$archive" "$out_dir/"; then
    echo
    echo "完成：$out_dir"
  else
    echo
    echo "解压失败。"
  fi
  pause_for_enter
}

list_archive() {
  local archive
  archive="$(read_path "请选择要查看内容的 RAR 压缩包：")"
  if [[ ! -f "$archive" ]]; then
    echo "这个压缩包不存在：$archive"
    pause_for_enter
    return
  fi
  echo
  "$UNRAR_BIN" l "$archive"
  pause_for_enter
}

test_archive() {
  local archive
  archive="$(read_path "请选择要测试的 RAR 压缩包：")"
  if [[ ! -f "$archive" ]]; then
    echo "这个压缩包不存在：$archive"
    pause_for_enter
    return
  fi
  echo
  "$UNRAR_BIN" t "$archive"
  pause_for_enter
}

show_help() {
  "$RAR_BIN" '-?'
  pause_for_enter
}

if ! check_tools; then
  [[ "${COMMAND_TOOL_NO_PAUSE:-0}" != "1" ]] && pause_for_enter
  exit 1
fi

while true; do
  clear
  echo "RAR CLI Helper for macOS"
  echo "========================="
  echo "1. 压缩文件/文件夹为 .rar"
  echo "2. 解压 .rar 压缩包"
  echo "3. 查看压缩包内容"
  echo "4. 测试压缩包是否正常"
  echo "5. 显示 rar 帮助"
  echo "6. 清理文件夹中的 macOS 隐藏垃圾文件"
  echo "0. 退出"
  echo
  printf "请选择："
  read -r choice
  path_choice="$(clean_path "$choice")"

  case "$choice" in
    1) make_archive ;;
    2) extract_archive ;;
    3) list_archive ;;
    4) test_archive ;;
    5) show_help ;;
    6) clean_mac_junk_only ;;
    0) clear; exit 0 ;;
    *)
      if [[ -e "$path_choice" ]]; then
        if [[ -f "$path_choice" && "${path_choice:l}" == *.rar ]]; then
          extract_archive "$path_choice"
        else
          make_archive "$path_choice"
        fi
      else
        echo "无效选择：$choice"
        echo "提示：可以输入 1 压缩，或直接把文件/文件夹拖到这里自动压缩。"
        pause_for_enter
      fi
      ;;
  esac
done
