# 1. Embeds assets/logo-*.png into seminar-landing.html as CSS variables (between the logos:start/end markers),
#    so the page needs no separate image files (the claude.ai artifact blocks outside images).
# 2. Builds own-domain/index.html from seminar-landing.html by adding the document head.
$root = $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding $false
$srcPath = Join-Path $root "seminar-landing.html"
$src = [IO.File]::ReadAllText($srcPath, [Text.Encoding]::UTF8)

$vars = @(
  @{ name = "--logo-expo";   file = "assets\logo-expo-laundry.png" },
  @{ name = "--logo-berani"; file = "assets\logo-berani.png" },
  @{ name = "--logo-laundrybiz"; file = "assets\logo-laundrybiz.png" },
  @{ name = "--logo-hipli"; file = "assets\logo-hipli.png" },
  @{ name = "--photo-nirwan"; file = "assets\nirwan.jpg" },
  @{ name = "--hero-bg"; file = "assets\hero-laundry.jpg" }
) | ForEach-Object {
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root $_.file)))
  $mime = if ($_.file -like "*.jpg") { "image/jpeg" } else { "image/png" }
  "  $($_.name): url(""data:$mime;base64,$b64"");"
}
# Pillar card backgrounds from "4 Pilar": cropped to 3:2 around a focus line, 900x600 JPEG.
Add-Type -AssemblyName System.Drawing
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$jq = New-Object System.Drawing.Imaging.EncoderParameters 1
$jq.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 72L
function Pillar-Var($name, $file, $focusY) {
  $img = [System.Drawing.Bitmap]::FromFile((Join-Path $root "4 Pilar\$file"))
  $img.SetResolution(96, 96)
  $sw = $img.Width; $sh = [int]($sw * 2 / 3)
  if ($sh -gt $img.Height) { $sh = $img.Height; $sw = [int]($sh * 3 / 2) }
  $sx = [int](($img.Width - $sw) / 2)
  $sy = [int][Math]::Max(0, [Math]::Min($img.Height - $sh, $img.Height * $focusY - $sh / 2))
  $out = New-Object System.Drawing.Bitmap 900, 600; $out.SetResolution(96, 96)
  $g = [System.Drawing.Graphics]::FromImage($out); $g.InterpolationMode = "HighQualityBicubic"; $g.PixelOffsetMode = "HighQuality"
  $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, 900, 600), (New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh), [System.Drawing.GraphicsUnit]::Pixel)
  $ms = New-Object IO.MemoryStream; $out.Save($ms, $jpeg, $jq)
  $b64 = [Convert]::ToBase64String($ms.ToArray())
  $g.Dispose(); $out.Dispose(); $img.Dispose(); $ms.Dispose()
  "  ${name}: url(""data:image/jpeg;base64,$b64"");"
}
$vars += Pillar-Var "--pilar-administrasi" "Administrasi.jpg" 0.55
$vars += Pillar-Var "--pilar-manajemen"    "Management.jpg"   0.5
$vars += Pillar-Var "--pilar-legalitas"    "Legalitas.png"    0.5
$vars += Pillar-Var "--pilar-marketing"    "Marketing.png"    0.62

# Activity gallery: every JPG/PNG in "Foto Referensi kegiatan" becomes a 760px-wide JPEG,
# shown as a CSS background like every other image on the page (<img src="data:..."> did not show in the artifact viewer).
# HEIC files are skipped (Windows here has no HEIC codec); export them as JPG first.
$photoDir = Join-Path $root "Foto Referensi kegiatan"
$photos = @(Get-ChildItem $photoDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(jpe?g|png)$' } | Sort-Object Name)
$skipped = @(Get-ChildItem $photoDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(heic|heif)$' })
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 74L
# Alt text per photo (matched on the start of the file name); anything else gets the generic text
$alts = @{
  "IMG_0594" = "Foto bersama peserta seminar BERANI dan LaundryBiz"
  "WhatsApp Image 2026-11-03 at 10.37.36" = "Penyerahan sertifikat penghargaan bersama Nirwan di kegiatan BERANI"
}
# Vertical crop focus per photo (CSS background-position y); default leans low, where people usually are
$focus = @{
  "WhatsApp Image 2026-11-03 at 10.37.36" = "38%"
}
$figs = @(); $galleryRules = @(); $n = 0
foreach ($f in $photos) {
  $n++
  $alt = "Dokumentasi kegiatan BERANI dan LaundryBiz"
  foreach ($k in $alts.Keys) { if ($f.Name.StartsWith($k)) { $alt = $alts[$k] } }
  $posY = "72%"
  foreach ($k in $focus.Keys) { if ($f.Name.StartsWith($k)) { $posY = $focus[$k] } }
  $img = [System.Drawing.Image]::FromFile($f.FullName)
  # respect the camera's EXIF orientation
  if ($img.PropertyIdList -contains 0x0112) {
    switch ([int]$img.GetPropertyItem(0x0112).Value[0]) { 3 { $img.RotateFlip("Rotate180FlipNone") } 6 { $img.RotateFlip("Rotate90FlipNone") } 8 { $img.RotateFlip("Rotate270FlipNone") } }
  }
  $w = [Math]::Min(760, $img.Width); $h = [int]($img.Height * $w / $img.Width)
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode = "HighQualityBicubic"; $g.DrawImage($img, 0, 0, $w, $h); $g.Dispose()
  $ms = New-Object IO.MemoryStream; $bmp.Save($ms, $enc, $ep)
  $b64 = [Convert]::ToBase64String($ms.ToArray()); $ms.Dispose(); $bmp.Dispose(); $img.Dispose()
  $vars += "  --galeri-${n}: url(""data:image/jpeg;base64,$b64"");"
  $galleryRules += ".gallery figure:nth-child($n) { background-image: var(--galeri-$n); background-position: 50% $posY; }"
  $figs += "        <figure class=""reveal"" role=""img"" aria-label=""$alt""></figure>"
}

$block = "/* logos:start */`n:root {`n" + ($vars -join "`n") + "`n}`n" + ($galleryRules -join "`n") + "`n/* logos:end */"
$src = [regex]::Replace($src, "/\* logos:start \*/[\s\S]*?/\* logos:end \*/", { param($m) $block })

$galleryHtml = "<!-- gallery:start -->`n" + ($figs -join "`n") + "`n<!-- gallery:end -->"
$src = [regex]::Replace($src, "<!-- gallery:start -->[\s\S]*?<!-- gallery:end -->", { param($m) $galleryHtml })
$src = [regex]::Replace($src, '<div class="gallery"( data-count="\d+")?>', "<div class=""gallery"" data-count=""$($photos.Count)"">")
$src = [regex]::Replace($src, '<section class="gallery-sec" id="kegiatan"( hidden)?>', $(if ($photos.Count) { '<section class="gallery-sec" id="kegiatan">' } else { '<section class="gallery-sec" id="kegiatan" hidden>' }))
Write-Output ("Gallery: {0} photo(s) embedded, {1} HEIC skipped" -f $photos.Count, $skipped.Count)
[IO.File]::WriteAllText($srcPath, $src, $utf8)

$head = @'
<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="Seminar Bisnis Laundry bersama Nirwan, CEO BERANI. Sabtu, 14 November 2026 di ICE BSD City. Daftar via WhatsApp.">
<meta property="og:title" content="Seminar Bisnis Laundry, 14 Nov 2026, ICE BSD City">
<meta property="og:description" content="Strategi Pengelolaan Bisnis dalam Menghadapi Persaingan. Bersama Nirwan, CEO BERANI.">

'@
New-Item -ItemType Directory -Force (Join-Path $root "own-domain") | Out-Null
$out = Join-Path $root "own-domain\index.html"
[IO.File]::WriteAllText($out, $head + $src + "`n</html>`n", $utf8)
Write-Output ("Built {0} ({1:N0} KB)" -f $out, ((Get-Item $out).Length / 1KB))
