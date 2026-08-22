# Osh

<p align="center">
  <em>معاينات Markdown جميلة في QuickLook ضمن Finder على macOS</em><br>
  Mermaid • KaTeX • GFM • جدول محتويات • رسوم بيانية • تصدير
</p>

<p align="center">
  <a href="https://github.com/Zeyadistired/Osh/stargazers">
    <img src="https://img.shields.io/github/stars/Zeyadistired/Osh?style=social" alt="نجوم GitHub">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?style=flat-square" alt="أحدث إصدار">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/downloads/Zeyadistired/Osh/total?style=flat-square" alt="التنزيلات">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/Zeyadistired/Osh?style=flat-square" alt="الترخيص">
  </a>
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README_ES.md">Español</a> •
  <a href="README_AR.md">العربية</a> •
  <a href="#-التثبيت-السريع-30-ثانية">التثبيت</a> •
  <a href="#️-استكشاف-الأخطاء-وإصلاحها">استكشاف الأخطاء</a>
</p>

---

## ✨ العرض التوضيحي

![عرض Osh التوضيحي](docs/assets/demo.gif)

<p align="center">
  <strong>اضغط <code>مسافة</code> في Finder ← معاينة فورية مع المخططات والرياضيات والمزيد.</strong>
</p>

<p align="center">
  <em>👋 إذا كان Osh مفيدًا لك، ففّر منحه</em>
  <a href="https://github.com/Zeyadistired/Osh/stargazers">⭐ نجمة على GitHub</a>!
</p>

---

## 🚀 التثبيت السريع (30 ثانية)

### يدويًا (DMG)

1. حمّل أحدث ملف `Osh.dmg` من صفحة [الإصدارات](https://github.com/Zeyadistired/Osh/releases)
2. افتح ملف DMG
3. اسحب **Osh.app** إلى مجلد **التطبيقات**

### Homebrew

> قريبًا — لم يُنشر tap مخصص لهذا المشروع بعد.
> في هذه الأثناء يمكنك تثبيت النسخة الأصلية:
> ```bash
> brew install --cask xykong/tap/flux-markdown
> ```

---

## 💡 لماذا Osh؟

| الميزة | الوصف |
|---------|-------------|
| 📊 **مخططات Mermaid** | مخططات معمارية ومخططات انسيابية ومخططات تسلسلية |
| 🧮 **رياضيات KaTeX** | تعبيرات رياضية داخل السطر وفي كتل منفصلة |
| 📝 **دعم GFM** | جداول وقوائم مهام وشطب وتنبيهات GitHub |
| 🎨 **تلوين الأكواد** | تلوين صياغة لأكثر من 40 لغة برمجة |
| 📊 **الرسوم البيانية** | دعم Vega وVega-Lite وGraphviz (DOT) |
| 📑 **لوحة المحتويات** | جدول محتويات تفاعلي مع تتبّع الأقسام |
| 📄 **بيانات YAML الوصفية** | تحليل تلقائي للـ frontmatter في جدول مرتب |
| 📤 **التصدير** | PDF ‏(Cmd+Shift+P) / HTML ‏(Cmd+Shift+E) |
| 🔍 **تكبير وتحريك** | Cmd +/-/0، Cmd + تمرير، وإيماءات القرص |
| 💾 **ذاكرة الموضع** | يتذكر موضع التمرير وآخر ملف تمت مشاهدته |
| 🌓 **السمات** | أنماط فاتح وداكن ومتزامن مع النظام |
| 📂 **صيغ الملفات** | يدعم .md و.mdx و.rmd و.qmd و.mdoc و.mdc و.mmd و.livemd و.mkd و.mkdn و.mkdown و.mdwn و.mdown و.markdown |

---

## ⚙️ الإعدادات (Cmd+,)

يتضمن Osh نافذة إعدادات مخصصة لتخصيص تجربتك:

- **المظهر**: التبديل بين السمات الفاتحة أو الداكنة أو المتزامنة مع النظام.
- **العرض**: تفعيل أو تعطيل دعم Mermaid وKaTeX والإيموجي.
- **المحرر**: ضبط حجم الخط الأساسي واختيار سمات تلوين الأكواد (GitHub، Monokai، Atom One Dark وغيرها).

---

## ⌨️ اختصارات لوحة المفاتيح

| الاختصار | الإجراء |
|----------|--------|
| `Space` | فتح معاينة QuickLook (في Finder) |
| `Cmd` + `+` / `-` / `0` | تكبير / تصغير / إعادة الضبط |
| `Cmd` + `Shift` + `E` | التصدير بصيغة HTML |
| `Cmd` + `Shift` + `P` | التصدير بصيغة PDF |
| `Cmd` + `,` | فتح الإعدادات |

---

## 🛠️ استكشاف الأخطاء وإصلاحها

<details dir="rtl">
<summary><strong>«التطبيق تالف» / «مطور غير موثوق»</strong></summary>

شغّل هذا الأمر في الطرفية (Terminal):
```bash
xattr -cr "/Applications/Osh.app"
```
</details>

<details dir="rtl">
<summary><strong>QuickLook لا يُظهر التحديثات</strong></summary>

أعد ضبط ذاكرة QuickLook المؤقتة:
```bash
qlmanage -r
```
</details>

<details dir="rtl">
<summary><strong>المعاينة لا تعمل إطلاقًا</strong></summary>

1. تأكد من وجود التطبيق في `/Applications/`
2. جرّب إعادة تشغيل Finder: ‏`killall Finder`
3. افحص `pluginkit -m -v` للتحقق من امتدادات QuickLook النشطة
</details>

**📚 مساعدة إضافية:** راجع [`docs/user/TROUBLESHOOTING.md`](docs/user/TROUBLESHOOTING.md) و[`docs/user/AUTO_UPDATE.md`](docs/user/AUTO_UPDATE.md)

**📖 فهرس التوثيق:** [`docs/README.md`](docs/README.md)

---

## مقارنة (إضافات Markdown لـ QuickLook)

| الميزة | Osh | [QLMarkdown](https://github.com/sbarex/QLMarkdown) | [qlmarkdown](https://github.com/whomwah/qlmarkdown) | [PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) |
| --- | --- | --- | --- | --- |
| التثبيت | brew cask / DMG | brew cask / DMG | يدويًا | App Store / DMG |
| Mermaid | نعم | نعم ([المصدر](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mermaid-diagrams)) | غير مذكور | غير مذكور |
| KaTeX / الرياضيات | نعم | نعم ([المصدر](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mathematical-expressions)) | غير مذكور | غير مذكور |
| GFM / التنبيهات | نعم | نعم (cmark-gfm؛ [المصدر](https://github.com/sbarex/QLMarkdown/releases/tag/1.0.18)) | جزئي (Discount؛ [المصدر](https://github.com/whomwah/qlmarkdown#introduction)) | غير مذكور |
| لوحة المحتويات | نعم | غير مذكور | لا | غير مذكور |
| الرسوم البيانية (Vega/DOT) | نعم | غير مذكور | لا | لا |
| التصدير (PDF/HTML) | نعم | لا | لا | لا |
| YAML Frontmatter | نعم | نعم | لا | لا |
| السمات | فاتح/داكن/النظام | قائمة على CSS ([المصدر](https://github.com/sbarex/QLMarkdown/blob/main/README.md#extensions)) | غير مذكور | عناصر تحكم أساسية ([المصدر](https://github.com/smittytone/PreviewMarkdown#adjusting-the-preview)) |
| التكبير | نعم | غير مذكور | لا | غير مذكور |
| استعادة موضع التمرير | نعم | غير مذكور | لا | غير مذكور |

> ملاحظات:
> - يستند هذا الجدول إلى ملفات README وملاحظات الإصدار العامة في الروابط المرجعية.
> - إذا لم تُذكر ميزة ما في المصادر، نضع «غير مذكور».

---

## البناء من الكود المصدري

```bash
git clone https://github.com/Zeyadistired/Osh.git
cd Osh
make install
```

## 📄 الترخيص

**يُوزَّع Osh بموجب GPL-3.0:**
- ✅ **مجاني** للاستخدام الشخصي والتعليمي ومشاريع المصادر المفتوحة
- ✅ يجب فتح مصدر أي تعديلات أيضًا بموجب GPL-3.0
- 📜 راجع [`LICENSE`](LICENSE) للشروط الكاملة

المشروع الأصلي مرخّص بترخيص مزدوج من مؤلفه؛ وتُدار تراخيص الاستخدام التجاري لنسخة FluxMarkdown الأصلية بواسطة **@xykong** — راجع [`LICENSE.COMMERCIAL`](LICENSE.COMMERCIAL) أو تواصل عبر **xy.kong@gmail.com**.

---

## 🙏 الإسناد

يعتمد هذا المشروع على [FluxMarkdown](https://github.com/xykong/flux-markdown) من [@xykong](https://github.com/xykong)، المرخّص بموجب GPL-3.0. كل الفضل في التصميم والتنفيذ الأصلي يعود لمؤلف المشروع الأصلي ومساهميه ([@timokox](https://github.com/timokox)، [@marko-cancar](https://github.com/marko-cancar)، [@withsivram](https://github.com/withsivram)، [@TeroRERO](https://github.com/TeroRERO)).

---

<p align="center" dir="rtl">
  <sub>مستوحى من <a href="https://github.com/shd101wyy/markdown-preview-enhanced">markdown-preview-enhanced</a> ومبني جزئيًا عليه</sub>
</p>
