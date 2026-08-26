# Sparkle Auto Update (Osh)

> Goal: let **Osh** update itself in-app via Sparkle.
>
> Bottom line: **GitHub Pages is not required**. The recommended approach is to serve `appcast.xml` from `raw.githubusercontent.com`.

---

## 1. The update feed (SUFeedURL)

Sparkle needs access to `appcast.xml` to check for updates.

### Method 1 (recommended): GitHub Raw (no Pages needed)

Set it in `Sources/OshApp/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/Zeyadistired/Osh/main/appcast.xml</string>
```

Pros:
- No GitHub Pages needed
- Simple, stable, fully under your control

Note:
- You **must** use the **raw** URL (returns the raw XML). Do not use GitHub's `blob` page URL (it returns HTML).

### Method 2 (optional): GitHub Pages

If you prefer Pages (e.g. a `github.io` domain feels more "product-like"):

1. Enable Pages in the repo settings
2. Choose the root of the branch you want (or a subdirectory)
3. Make sure `appcast.xml` lives there
4. Set:

```xml
<key>SUFeedURL</key>
<string>https://YOUR_USERNAME.github.io/YOUR_REPO/appcast.xml</string>
```

---

## 2. Generating appcast.xml on release

### 2.1 Generate signatures and update the appcast

```bash
./scripts/generate-appcast.sh build/artifacts/Osh.dmg
```

The script will:
- Generate a `sparkle:edSignature` for the DMG
- Update/insert the entry in `appcast.xml`

### 2.2 Commit and push appcast.xml

```bash
git add appcast.xml
git commit -m "chore(sparkle): update appcast for v<VERSION>"
git push
```

---

## 3. Security best practices

### 3.1 Private key management

⚠️ **Never commit private keys to Git.**

`.gitignore` should include:

```gitignore
.sparkle-keys/
```

Recommended storage:
- 1Password / Bitwarden and similar tools
- Encrypted offline storage

### 3.2 CI/CD

If you generate signatures in CI:
- Store the private key in GitHub Secrets
- Write it to a temporary file at runtime and delete it afterwards

---

## 4. Common troubleshooting

### 4.1 The feed URL returns HTML instead of XML

Symptom: update check fails, logs show an XML parsing error.

Cause: `SUFeedURL` points at GitHub's `blob` page.

Fix: use the raw URL:

`https://raw.githubusercontent.com/Zeyadistired/Osh/main/appcast.xml`

### 4.2 Signature verification fails

Cause:
- `sparkle:edSignature` does not match the actual DMG

Fix:

```bash
./scripts/generate-appcast.sh build/artifacts/Osh.dmg
```
