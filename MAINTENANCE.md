# Hasan Sarıcı Academic Website — Uzun Vadeli Bakım El Kitabı

Bu dosya, `https://hasansarici.com` sitesinin yıllar boyunca güvenli ve sürdürülebilir biçimde güncellenmesi için ana başvuru belgesidir.

## 1. Mimari: görevleri birbirinden ayır

Sistem üç katmanlıdır:

1. **Dropbox Excel — insan tarafından düzenlenen içerik yönetim dosyası**
   - `Hasan_Sarici_Website/website_content.xlsx`
2. **GitHub repository — sürüm kontrollü teknik kaynak**
   - `data/*.csv`, Quarto/R kaynakları, PDF kaynakları ve workflow'lar
3. **GitHub Pages — canlı yayın**
   - `https://hasansarici.com`

Aktif Git repository'sini Dropbox içine taşıma. Dropbox ile Git'in aynı proje klasöründeki dosyaları eşzamanlı yönetmesi gereksiz çakışma riski yaratır. Dropbox içerik/yedek alanı; GitHub ise kod, geçmiş ve deployment alanıdır.

## 2. Dropbox klasör yapısı

Normal yapı:

```text
Hasan_Sarici_Website/
├── website_content.xlsx
├── images/
├── documents/
├── cv/
└── backups/
```

- `website_content.xlsx`: normal akademik güncellemelerin ana düzenleme yüzeyi
- `cv/`: başarılı güncellemeden sonra en yeni Türkçe/İngilizce CV PDF kopyaları
- `backups/`: her normal güncellemede Excel yedeği ve başarılı push sonrası tam Git bundle yedeği
- `images/` ve `documents/`: ileride siteye eklenecek kullanıcı tarafından yönetilen medya/dokümanlar için ayrılmış alan

## 3. Excel sekmeleri ve Git karşılıkları

`UPDATE_WEBSITE.R`, Excel sekmelerini aşağıdaki CSV dosyalarına dönüştürür:

| Excel sekmesi | Git build girdisi |
|---|---|
| `Profile` | `data/profile.csv` |
| `Research` | `data/research_interests.csv` |
| `Education` | `data/education.csv` |
| `Experience` | `data/experience.csv` |
| `Teaching` | `data/teaching.csv` |
| `Publications` | `data/publications.csv` |
| `Projects` | `data/projects.csv` |
| `Networks` | `data/networks.csv` |
| `Professional` | `data/professional.csv` |
| `Conferences` | `data/conferences.csv` |

**Kritik kural:** Excel sekme adlarını, sütun adlarını veya sütun sırasını değiştirme. Normal içerik değişikliklerinde GitHub'daki CSV'leri elle düzenleme; bir sonraki Excel aktarımı bu elle değişikliği ezebilir.

## 4. En kolay normal güncelleme akışı

Yayın, proje, görev, eğitim, ders, COST ağı, sertifika, kongre veya profil bilgisi değiştiğinde:

1. Dropbox'taki `website_content.xlsx` dosyasını aç.
2. İlgili sekmede kaydı ekle/düzelt.
3. Dosyayı kaydet ve Dropbox senkronizasyonunun bitmesini bekle.
4. RStudio'da `hasan-sarici-website` projesini aç.
5. `UPDATE_WEBSITE.R` dosyasını aç ve **Source** düğmesine bas.
6. Script'in gösterdiği değişiklikleri kontrol et.
7. Yayınlamak istiyorsan sorulduğunda tam olarak `EVET` yaz.
8. GitHub Actions'taki deploy'un yeşil olmasını bekle.

Normal bir içerik güncellemesinde başka Git/GitHub komutu yazmak gerekmez.

## 5. `UPDATE_WEBSITE.R` hangi güvenlik kontrollerini yapar?

Script otomatik olarak:

- yerel repository'de kaydedilmemiş değişiklik varsa **hiçbir şeyi ezmeden durur**;
- `git pull --ff-only origin main` ile uzak repository'yi güvenli biçimde eşitler;
- Dropbox Excel dosyasını standart macOS Dropbox konumlarında otomatik bulur;
- zorunlu sekme/sütun yapısını doğrular;
- ID, sıralama, yayın statüsü, kategori ve kontrollü alanları doğrular;
- yanlışlıkla büyük miktarda satır silinmiş görünüyorsa durur;
- aktarım öncesinde `backups/website_content_TARIH_SAAT.xlsx` oluşturur;
- Excel'i `data/*.csv` dosyalarına dönüştürür;
- iki PDF CV'yi ve tüm iki dilli siteyi yeniden üretir;
- `scripts/validate_site.py` ile 14 sayfa, iki PDF, bağlantılar ve SEO/dil metadatasını doğrular;
- commit öncesinde değişen dosyaları gösterir;
- yalnızca kullanıcı `EVET` yazarsa commit/push yapar;
- başarılı push sonrasında güncel PDF CV'leri Dropbox `cv/` klasörüne kopyalar;
- `backups/` altında tam Git geçmişini taşıyan doğrulanmış `.bundle` yedeği oluşturur.

Build/validator veya başka bir kritik aşama başarısız olursa script Git kaynaklarını önceki temiz hâline geri getirir. Excel'deki düzenleme ve oluşturulan Excel yedeği korunur.

## 6. Excel kullanırken önemli veri kuralları

### ID alanları

- Yeni yayın: `PUB021`, `PUB022`, ... biçiminde devam et.
- Yeni proje: `PROJ003`, `PROJ004`, ... biçiminde devam et.
- Aynı ID'yi ikinci kez kullanma.

### `order` / `display_order`

Pozitif ve benzersiz tam sayı olmalıdır. Görüntüleme sırasını bu değerler belirler.

### Yayın statüleri

`Publications` sekmesindeki yayımlanmamış çalışmalar için:

- `submitted` = gönderildi / editoryal süreçte
- `peer_review` = gerçekten hakem değerlendirmesinde
- `revising` = revizyon / yeniden gönderim hazırlığı
- `published` = yayımlandı

Sadece dergiye gönderilmiş bir çalışma için `peer_review` kullanma. Dergi kararı geldiğinde Excel kaydını güncelle.

Yayımlanmış bir çalışma için:

- `status = published`
- makaleyse `category = peer_reviewed`
- kitap için `category = book`
- kitap bölümü için `category = book_chapter`
- yıl bilgisi zorunludur.

Yayın sürecindeki kayıtlar için `category = under_review` kullanılır; public site gerçek statüyü ayrıca gösterir.

### DOI

DOI varsa sadece DOI değerini yaz:

```text
10.xxxx/xxxxx
```

`https://doi.org/` kısmını ekleme.

## 7. Dropbox dosyası Mac'te bulunamazsa

`UPDATE_WEBSITE.R`, yaygın Dropbox masaüstü konumlarını otomatik tarar. Dosya bulunamazsa önce Dropbox masaüstü uygulamasının çalıştığını ve dosyanın Mac'e senkronize olduğunu kontrol et.

Gerekirse RStudio'da yalnızca o oturum için tam yolu tanımlayabilirsin:

```r
Sys.setenv(
  HASAN_SITE_CONTENT_XLSX = "/tam/yol/Hasan_Sarici_Website/website_content.xlsx"
)
```

Sonra `UPDATE_WEBSITE.R` dosyasını yeniden Source et.

## 8. Git repository temiz değil uyarısı alırsan

Script burada özellikle durur. **Force/reset yapma.** Önce:

```r
site_dir <- path.expand("~/Documents/hasan-sarici-website")

system2(
  "git",
  c("-C", shQuote(site_dir), "status", "--short")
)
```

çıktısını incele. Değişiklik sana aitse kaybetmeden commit/stash stratejisini belirle. Ne olduğunu bilmiyorsan işlem yapmadan önce incele.

## 9. Altyapı veya sayfa tasarımı değişikliği

`UPDATE_WEBSITE.R` yalnızca normal yapılandırılmış akademik veri güncellemeleri içindir. Aşağıdakiler **altyapı/development değişikliği** sayılır:

- `.qmd` sayfa metni veya düzeni
- `styles.css` / `polish.css`
- `R/` helper kodları
- `_pdf/` CV tasarımı
- `build_site.R`
- `scripts/validate_site.py`
- `.github/workflows/`
- domain/hosting/dil mimarisi

Bu değişikliklerde standart manuel akış:

1. `git pull --ff-only`
2. küçük ve kontrollü değişiklik
3. `build_site.R`
4. `scripts/validate_site.py`
5. `git diff` / `git status`
6. commit + push
7. GitHub Actions yeşil
8. canlı site kontrolü

## 10. Manuel build ve validator

RStudio Console:

```r
site_dir <- path.expand("~/Documents/hasan-sarici-website")
source(file.path(site_dir, "build_site.R"), chdir = TRUE)
```

Ardından:

```r
system2(
  "python3",
  c(
    shQuote(file.path(site_dir, "scripts", "validate_site.py")),
    shQuote(file.path(site_dir, "_site"))
  )
)
```

Beklenen sonuç:

```text
SITE VALIDATION PASSED
```

## 11. Sabitlenmiş üretim ortamı

Üretim zinciri bilinçli olarak sabitlenmiştir:

- R: `4.6.0`
- Quarto CLI: `1.10.18`
- babelquarto: workflow'da tam commit SHA ile sabit
- GitHub Actions: major etiketi yerine tam commit SHA ile sabit

Bu sürümleri yalnızca daha yenisi çıktığı için değiştirme. Yükseltme ayrı bakım işi olarak test edilmelidir.

Dependabot GitHub Actions güncellemeleri önerebilir. **Körlemesine merge etme.** Önce CI build/validator sonucunu incele.

## 12. Otomatik koruma katmanları

### Deploy öncesi doğrulama

Her `main` push'unda site oluşturulur ve `scripts/validate_site.py` çalışır. Doğrulama başarısızsa deploy edilmez; son çalışan canlı sürüm korunur.

### Haftalık canlı site kontrolü

`.github/workflows/health-check.yml` düzenli olarak ana TR/EN sayfaları, sitemap, iki PDF CV ve `www` yönlendirmesini kontrol eder.

## 13. Aylık bakım — yaklaşık 5 dakika

Ayda bir:

1. GitHub Actions'ta son deploy ve health check çalışmalarının yeşil olduğunu kontrol et.
2. Dependabot PR varsa acele etmeden değerlendir.
3. `https://hasansarici.com` ve `https://www.hasansarici.com` adreslerini aç.
4. TR ↔ EN geçişini test et.
5. Türkçe ve İngilizce PDF CV'yi aç.
6. Dropbox `backups/` klasöründe yakın tarihli yedeklerin oluştuğunu kontrol et.

## 14. Üç aylık akademik içerik kontrolü

Üç ayda bir Excel üzerinden:

- yayın statülerini ve yeni DOI'leri,
- proje durumlarını,
- akademik görevleri,
- dersleri,
- COST/araştırma ağı üyeliklerini,
- eğitim/sertifika bilgilerini,
- kongre kayıtlarını

gözden geçir.

Özellikle `submitted / peer_review / revising` kayıtlarının güncel olup olmadığını kontrol et.

## 15. Yıllık kritik kontrol

Her yıl alan adı yenileme tarihinden en az bir ay önce:

1. Cloudflare Registrar'da `hasansarici.com` auto-renew durumunu kontrol et.
2. Ödeme yönteminin geçerli olduğunu doğrula.
3. GitHub ve Cloudflare hesaplarına erişebildiğini doğrula.
4. Her iki hesapta 2FA/passkey ve çevrimdışı recovery code yedeğini kontrol et.
5. GitHub Pages custom domain ayarının hâlâ `hasansarici.com` olduğunu kontrol et.
6. DNS'teki GitHub domain verification TXT kaydını koru.
7. Çalışan A/CNAME DNS kayıtlarını sebepsiz değiştirme.
8. Dropbox `backups/` klasöründen en az bir `.bundle` dosyasının bulunduğunu ve ayrıca başka bir fiziksel/bulut konumuna kopyalandığını doğrula.

## 16. Yedekleme katmanları

Normal workflow'da artık üç ayrı geri dönüş noktası vardır:

1. **Dropbox dosya sürüm geçmişi** — `website_content.xlsx`
2. **Timestamped Excel kopyaları** — `backups/website_content_*.xlsx`
3. **Tam Git bundle** — `backups/hasan-sarici-website_*.bundle`

Bunlara ek olarak GitHub her commit'in CSV/kod geçmişini tutar.

En az yılda bir kez önemli bir `.bundle` dosyasını Dropbox dışında ikinci bir konuma da kopyala.

## 17. Bir gün site bozulursa

### Senaryo A — Son push'tan sonra site bozuldu

1. GitHub Actions'ta başarısız adımı bul.
2. Son çalışan commit'i tespit et.
3. Hatalı commit'i geçmişi yeniden yazmadan `git revert` ile geri al.
4. Revert commit'ini push et.

`git reset --hard` + force push ile geçmişi silme.

### Senaryo B — Build başarılı ama canlı site açılmıyor

Sırayla kontrol et:

1. GitHub Pages deployment sonucu
2. custom domain ayarı
3. HTTPS sertifika durumu
4. Cloudflare DNS A ve `www` CNAME kayıtları
5. domain kayıt/yenileme durumu

Kodda değişiklik yapmadan önce altyapı sorunu olup olmadığını ayır.

### Senaryo C — Yerel Git klasörü kayboldu

GitHub'dan repository'yi yeniden clone et. GitHub erişimi de kaybolmuşsa Dropbox `backups/` altındaki doğrulanmış `.bundle` yedeğinden repository yeniden kurulabilir.

### Senaryo D — Excel'de yanlış değişiklik yaptın ama henüz yayınlamadın

Dropbox sürüm geçmişinden veya `backups/website_content_*.xlsx` dosyasından önceki içeriği geri getir. GitHub/canlı site henüz etkilenmemiştir.

### Senaryo E — Excel'deki yanlış değişikliği yayınladın

Git geçmişi eski `data/*.csv` değerlerini korur. En güvenli yaklaşım yanlış commit'i `git revert` ile geri almak ve ardından Excel dosyasını da doğru değerlerle düzeltmektir. Aksi hâlde sonraki Excel aktarımı hatayı yeniden üretebilir.

## 18. Değiştirilmemesi gereken temel varsayımlar

Bilinçli bir mimari geçiş yapılmadıkça:

- Canonical domain: `https://hasansarici.com/`
- Ana dil: Türkçe
- İkinci dil: İngilizce
- TR sayfalar kökte, EN sayfalar `/en/` altında
- Normal içerik yöneticisi: Dropbox `website_content.xlsx`
- Teknik/verisyon kontrollü build girdisi: `data/*.csv`
- Build giriş noktası: `build_site.R`
- Normal güncelleme giriş noktası: `UPDATE_WEBSITE.R`
- Deploy branch'i: `main`
- Hosting: GitHub Pages / GitHub Actions

Bunlardan biri değişecekse bunu normal içerik güncellemesi değil **altyapı migrasyonu** olarak ele al.

## 19. Kısa rutin kontrol listesi

Normal akademik güncellemede artık yalnızca:

1. Dropbox Excel'i düzenle ve kaydet.
2. RStudio'da `UPDATE_WEBSITE.R` → **Source**.
3. Değişiklikleri oku.
4. Doğruysa `EVET` yaz.
5. GitHub Actions yeşil olunca canlı siteyi kontrol et.

Geri kalan eşitleme, backup, CSV üretimi, build, validator, commit, push, CV kopyalama ve Git bundle işlemleri script tarafından yapılır.
