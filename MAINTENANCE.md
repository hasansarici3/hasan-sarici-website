# Hasan Sarıcı Academic Website — Uzun Vadeli Bakım El Kitabı

Bu dosya, `https://hasansarici.com` sitesinin yıllar boyunca güvenli ve sürdürülebilir biçimde güncellenmesi için ana başvuru belgesidir.

## 1. Altın kural: Her yerel değişiklikten önce eşitle

RStudio Console'da:

```r
site_dir <- path.expand("~/Documents/hasan-sarici-website")

system2(
  "git",
  c(
    "-C", shQuote(site_dir),
    "pull",
    "--ff-only",
    "origin",
    "main"
  )
)
```

`--ff-only` özellikle kullanılır. Böylece yerel ve uzak geçmiş beklenmedik biçimde ayrışmışsa Git otomatik ve riskli bir birleştirme yapmaz.

## 2. Kaynağın nerede olduğunu bil

Normal akademik içerik güncellemeleri mümkün olduğunca `data/` altındaki CSV dosyalarından yapılmalıdır.

| Güncellenecek bilgi | Ana kaynak |
|---|---|
| İletişim ve mevcut kurumsal bağlılık | `data/profile.csv` |
| Araştırma ilgi alanları | `data/research_interests.csv` |
| Eğitim | `data/education.csv` |
| Akademik görevler | `data/experience.csv` |
| Verilen dersler | `data/teaching.csv` |
| Yayınlar ve yayın hattı | `data/publications.csv` |
| Araştırma projeleri | `data/projects.csv` |
| Uluslararası araştırma ağları | `data/networks.csv` |
| Sertifikalar, spor, diller ve beceriler | `data/professional.csv` |
| Kongre sunumları | `data/conferences.csv` |

Sayfa metinleri `.qmd` dosyalarındadır. Görünüm `styles.css` ve `polish.css`; dinamik üretim `R/`; PDF CV kaynakları `_pdf/` altındadır.

**Elle değiştirilmemesi gerekenler:**

- `_site/` — derleme çıktısıdır.
- `assets/documents/*.pdf` — `build_site.R` tarafından yeniden üretilir.
- GitHub Pages üzerindeki yayımlanmış dosyalar — kaynak repository üzerinden güncellenmelidir.

## 3. Yayın statülerini doğru kullan

`data/publications.csv` içindeki yayımlanmamış çalışmalar için:

- `submitted` = gönderildi / editoryal süreçte
- `peer_review` = gerçekten hakem değerlendirmesinde
- `revising` = revizyon / yeniden gönderim hazırlığı
- `published` = yayımlandı

Sadece dergiye gönderilmiş bir çalışma için `peer_review` kullanma. Dergi kararı geldiğinde veri tabanındaki statüyü güncelle.

## 4. Standart güncelleme akışı

### A. Önce GitHub ile eşitle

1. Bölüm 1'deki `git pull --ff-only` komutunu çalıştır.
2. Hata varsa değişiklik yapmadan önce nedeni çöz.

### B. Yalnızca kaynak dosyaları düzenle

Yayın, proje, görev vb. için önce ilgili CSV'yi; açıklama metni gerekiyorsa ilgili `.qmd` dosyasını değiştir.

### C. Yerelde tam siteyi üret

```r
source(file.path(site_dir, "build_site.R"), chdir = TRUE)
```

Bu işlem hem web sitesini hem Türkçe/İngilizce PDF CV'leri üretir.

### D. Otomatik doğrulayıcıyı çalıştır

```r
system2(
  "python3",
  c(
    shQuote(file.path(site_dir, "scripts", "validate_site.py")),
    shQuote(file.path(site_dir, "_site"))
  )
)
```

Beklenen sonuç `SITE VALIDATION PASSED` olmalıdır. Doğrulayıcı; 14 TR/EN sayfayı, PDF'leri, iç bağlantıları, canonical/hreflang kayıtlarını, sitemap ve robots dosyalarını kontrol eder.

### E. Değişiklikleri gözden geçir

```r
system2("git", c("-C", shQuote(site_dir), "status", "--short"))
system2("git", c("-C", shQuote(site_dir), "diff", "--stat"))
```

Beklemediğin dosyalar değişmişse commit etmeden önce incele.

### F. Commit ve push

RStudio Git paneli kullanılabilir. Console tercih edilirse örnek:

```r
system2("git", c("-C", shQuote(site_dir), "add", "-A"))
system2(
  "git",
  c(
    "-C", shQuote(site_dir),
    "commit",
    "-m", shQuote("Update academic website content")
  )
)
system2("git", c("-C", shQuote(site_dir), "push", "origin", "main"))
```

### G. Yayını doğrula

GitHub Actions'taki **Build and Deploy Academic Website** çalışması yeşil olmalıdır. Deploy tamamlandıktan sonra en azından ana sayfa, ilgili değişen sayfa, TR/EN geçişi ve PDF bağlantıları kontrol edilmelidir.

## 5. Sabitlenmiş üretim ortamı

Üretim zinciri bilinçli olarak sabitlenmiştir:

- R: `4.6.0`
- Quarto CLI: `1.10.18`
- babelquarto: repository içindeki workflow'da tam commit SHA ile sabitlenir
- GitHub Actions: major etiketi yerine tam commit SHA ile çağrılır

Bu sürümleri yalnızca "daha yenisi var" diye değiştirme. Yükseltme ayrı bir bakım işi olarak ele alınmalı, yerelde ve GitHub Actions'ta test edilmeli, ardından site doğrulayıcısı geçmelidir.

Dependabot ayda bir GitHub Actions güncelleme önerileri açabilir. **Dependabot PR'larını körlemesine merge etme.** Önce build/validator sonuçlarını ve değişen action sürümünü incele.

## 6. Otomatik koruma katmanları

### Deploy öncesi doğrulama

Her `main` push'unda site oluşturulduktan sonra `scripts/validate_site.py` çalışır. Doğrulama başarısızsa site deploy edilmez; son çalışan canlı sürüm korunur.

### Haftalık canlı site kontrolü

`.github/workflows/health-check.yml` haftalık olarak:

- Türkçe ana sayfayı,
- İngilizce ana sayfayı,
- sitemap'i,
- iki PDF CV'yi,
- `www` → apex yönlendirmesini

kontrol eder.

GitHub, uzun süre hiç repository etkinliği olmayan bazı public repository'lerde zamanlanmış workflow'ları devre dışı bırakabilir. Bu nedenle haftalık workflow faydalı bir güvenlik katmanıdır ancak alan adı/hesap takibinin yerine geçmez.

## 7. Aylık bakım — yaklaşık 5 dakika

Ayda bir:

1. GitHub Actions'ta son deploy ve health check çalışmalarının yeşil olduğunu kontrol et.
2. Dependabot PR varsa acele etmeden değerlendir.
3. `https://hasansarici.com` ve `https://www.hasansarici.com` adreslerini aç.
4. TR ↔ EN geçişini bir kez test et.
5. Türkçe ve İngilizce PDF CV'yi bir kez aç.

## 8. Üç aylık akademik içerik kontrolü

Üç ayda bir:

- yayın statülerini,
- yeni DOI'leri,
- proje durumlarını,
- akademik görevleri,
- dersleri,
- COST/araştırma ağı üyeliklerini,
- eğitim/sertifika bilgilerini

gözden geçir. Özellikle "submitted / peer_review / revising" kayıtlarının güncel olup olmadığını kontrol et.

## 9. Yıllık kritik kontrol

Her yıl alan adı yenileme tarihinden en az bir ay önce:

1. Cloudflare Registrar'da `hasansarici.com` auto-renew durumunu kontrol et.
2. Ödeme kartının/geçerli ödeme yönteminin çalıştığını doğrula.
3. GitHub hesabına erişebildiğini doğrula.
4. Cloudflare hesabına erişebildiğini doğrula.
5. Her iki hesapta 2FA/passkey ve çevrimdışı recovery code yedeğini kontrol et.
6. GitHub Pages custom domain ayarının hâlâ `hasansarici.com` olduğunu kontrol et.
7. DNS'teki GitHub domain verification TXT kaydını koru.
8. Çalışan A/CNAME DNS kayıtlarını sebepsiz değiştirme.
9. Yeni bir tam Git bundle yedeği oluştur.

## 10. Repository dışı tam yedek

GitHub tek kopya olmamalıdır. Yılda en az bir kez ve büyük altyapı değişikliklerinden önce tam Git bundle oluştur.

RStudio Console:

```r
backup_file <- file.path(
  path.expand("~/Documents"),
  paste0(
    "hasan-sarici-website-",
    format(Sys.Date(), "%Y-%m-%d"),
    ".bundle"
  )
)

system2(
  "git",
  c(
    "-C", shQuote(site_dir),
    "bundle",
    "create",
    shQuote(backup_file),
    "--all"
  )
)

system2("git", c("bundle", "verify", shQuote(backup_file)))
backup_file
```

Oluşan `.bundle` dosyasını **bilgisayar dışında ikinci bir konuma** kopyala (ör. güvenilir bulut depolama veya harici disk). Bundle tüm Git geçmişini ve branch/tag referanslarını taşır.

## 11. Bir gün site bozulursa

### Senaryo A — Son push'tan sonra site bozuldu

1. GitHub Actions'ta başarısız adımı bul.
2. Son çalışan commit'i tespit et.
3. Hatalı commit'i geçmişi yeniden yazmadan `git revert` ile geri al.
4. Yeni revert commit'ini push et.

`git reset --hard` + force push ile geçmişi silme.

### Senaryo B — Build başarılı ama canlı site açılmıyor

Sırayla kontrol et:

1. GitHub Pages deployment sonucu
2. GitHub Pages custom domain ayarı
3. HTTPS sertifika durumu
4. Cloudflare DNS A ve `www` CNAME kayıtları
5. Domain kayıt/yenileme durumu

Kodda değişiklik yapmadan önce altyapı sorunu olup olmadığını ayır.

### Senaryo C — Yerel klasör kayboldu

GitHub'dan repository'yi yeniden clone et. GitHub erişimi de kaybolmuşsa doğrulanmış `.bundle` yedeğinden repository oluşturulabilir.

### Senaryo D — Bir CSV veya kaynak dosya yanlış değiştirildi

Git geçmişindeki önceki sürümü karşılaştır. Gerekirse ilgili commit'i `git revert` ile geri al. Üretilmiş `_site` veya PDF dosyalarından kaynak veri geri kurmaya çalışma.

## 12. Değiştirilmemesi gereken temel varsayımlar

Bilinçli bir mimari geçiş yapılmadıkça aşağıdakiler sabittir:

- Canonical domain: `https://hasansarici.com/`
- Ana dil: Türkçe
- İkinci dil: İngilizce
- TR sayfalar kökte, EN sayfalar `/en/` altında
- Build giriş noktası: `build_site.R`
- Deploy kaynağı: `main`
- Hosting: GitHub Pages / GitHub Actions
- Akademik verinin ana kaynağı: `data/*.csv`

Bu varsayımlardan biri değişecekse bunu normal içerik güncellemesi değil **altyapı migrasyonu** olarak ele al.

## 13. Bakım değişikliği için kısa kontrol listesi

Her normal güncellemede sıra:

1. `pull --ff-only`
2. Kaynak veriyi/metni değiştir
3. `build_site.R`
4. `scripts/validate_site.py`
5. Git diff/status kontrolü
6. commit + push
7. GitHub Actions yeşil
8. canlı sitede hızlı kontrol

Bu sekiz adım izlendiğinde günlük akademik güncellemeler ile site altyapısı birbirinden ayrılır ve geri dönüş yolu her zaman Git geçmişinde korunur.
