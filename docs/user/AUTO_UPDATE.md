# Sparkle Auto Update (Osh)

> 目标：让 **Osh** 使用 Sparkle 实现应用内自动更新。
> 
> 结论：**不需要启用 GitHub Pages**。推荐直接使用 `raw.githubusercontent.com` 托管 `appcast.xml`。

---

## 1. 更新源（SUFeedURL）

Sparkle 需要访问 `appcast.xml` 来检查更新。

### 方法 1（推荐）：GitHub Raw（无需 Pages）

在 `Sources/Markdown/Info.plist` 中设置：

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/Zeyadistired/Osh/main/appcast.xml</string>
```

优点：
- 无需 GitHub Pages
- 链路简单，稳定可控

注意：
- 必须使用 **raw** URL（返回 XML 原文），不要用 GitHub 的 `blob` 页面 URL（会返回 HTML）。

### 方法 2（可选）：GitHub Pages

如果你想用 Pages（例如希望 `github.io` 域名更“产品化”）：

1. 在 GitHub 仓库设置中启用 Pages
2. 选择 `master` 分支的根目录（或你指定的目录）
3. 确保 `appcast.xml` 在该目录下
4. 设置：

```xml
<key>SUFeedURL</key>
<string>https://YOUR_USERNAME.github.io/YOUR_REPO/appcast.xml</string>
```

---

## 2. 发布时生成 appcast.xml

### 2.1 生成签名并更新 appcast

```bash
./scripts/generate-appcast.sh build/artifacts/Osh.dmg
```

脚本会：
- 对 DMG 生成 `sparkle:edSignature`
- 更新/插入 `appcast.xml` 条目

### 2.2 提交并推送 appcast.xml

```bash
git add appcast.xml
git commit -m "chore(sparkle): update appcast for v<VERSION>"
git push
```

---

## 3. 安全最佳实践

### 3.1 私钥管理

⚠️ **绝对不要提交私钥到 Git**。

`.gitignore` 应包含：

```gitignore
.sparkle-keys/
```

推荐存储方式：
- 1Password / Bitwarden 等
- 加密的离线存储

### 3.2 CI/CD

如果你在 CI 里生成签名：
- 使用 GitHub Secrets 存储私钥
- 运行时写入临时文件，用完即删

---

## 4. 常见排障

### 4.1 更新源拿到的是 HTML

现象：更新检查失败，日志里出现 XML 解析错误。

原因：`SUFeedURL` 指向了 GitHub 的 `blob` 页面。

修复：改成 raw：

`https://raw.githubusercontent.com/Zeyadistired/Osh/main/appcast.xml`

### 4.2 签名校验失败

原因：
- `sparkle:edSignature` 与实际 DMG 不匹配

修复：

```bash
./scripts/generate-appcast.sh build/artifacts/Osh.dmg
```
