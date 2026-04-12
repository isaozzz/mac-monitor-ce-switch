# MonitorSwitch

macOS menu bar app to switch between **extended display** and **mirroring** modes, and to change the **main display**.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Lives in the macOS menu bar (no Dock icon)
- One-click switching between extended and mirrored display modes
- Switch which display is the main display (menu bar position)
- Shows current mode with a checkmark
- Supports multiple external displays

## Requirements

- macOS 13.0 (Ventura) or later
- Two or more connected displays

## Install

```bash
git clone https://github.com/isaozzz/mac-monitor-ce-switch.git
cd mac-monitor-ce-switch
make install
```

This builds the binary, copies it to `~/bin/`, registers a LaunchAgent, and starts the app. It will also auto-start on every login.

## Uninstall

```bash
make uninstall
```

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## 概要（日本語）

macOSのメニューバーに常駐し、ディスプレイの**拡張／ミラーリング切り替え**と**主ディスプレイの変更**をワンクリックで行えるアプリです。

## 機能

- メニューバー常駐（Dockアイコンなし）
- 拡張ディスプレイ／ミラーリングのワンクリック切り替え
- 主ディスプレイ（メニューバーの表示位置）の切り替え
- 現在のモードにチェックマーク表示
- 複数ディスプレイ対応

## 動作環境

- macOS 13.0 (Ventura) 以降
- ディスプレイ2台以上

## インストール

```bash
git clone https://github.com/isaozzz/mac-monitor-ce-switch.git
cd mac-monitor-ce-switch
make install
```

ビルド、`~/bin/` へのコピー、LaunchAgent登録、アプリ起動を一括で行います。以降はログイン時に自動起動します。

## アンインストール

```bash
make uninstall
```
