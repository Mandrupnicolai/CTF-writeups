[CmdletBinding()]
param(
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

function Escape-PdfString {
  param([string]$s)
  # PDF literal strings need escaping for backslash and parentheses.
  return $s.Replace("\", "\\").Replace("(", "\(").Replace(")", "\)")
}

function Convert-MarkdownToLines {
  param([string]$markdown)

  $lines = New-Object System.Collections.Generic.List[string]

  $inFrontMatter = $false
  $frontMatterSeen = 0
  $inCode = $false

  foreach ($raw in ($markdown -split "\r?\n")) {
    $line = $raw

    if ($frontMatterSeen -lt 2 -and $line.Trim() -eq "---") {
      $frontMatterSeen++
      $inFrontMatter = $frontMatterSeen -lt 2
      continue
    }
    if ($inFrontMatter) { continue }

    if ($line.Trim().StartsWith('```')) {
      $inCode = -not $inCode
      continue
    }

    if (-not $inCode) {
      # Remove simple markdown formatting.
      $line = $line -replace "`t", "  "
      $line = $line -replace "\*\*(.+?)\*\*", '$1'
      $line = $line -replace "\*(.+?)\*", '$1'
      $line = $line -replace '`(.+?)`', '$1'

      # Convert links: [text](url) -> text (url)
      $line = [regex]::Replace($line, "\[([^\]]+)\]\(([^)]+)\)", '$1 ($2)')
    } else {
      # Keep code blocks monospace-friendly.
      $line = "    " + $line
    }

    $lines.Add($line)
  }

  return ,$lines.ToArray()
}

function Wrap-Lines {
  param(
    [string[]]$Lines,
    [int]$MaxChars = 95
  )

  $out = New-Object System.Collections.Generic.List[string]
  foreach ($l in $Lines) {
    if ($l.Length -le $MaxChars) {
      $out.Add($l)
      continue
    }

    $remaining = $l
    while ($remaining.Length -gt $MaxChars) {
      $cut = $remaining.LastIndexOf(" ", $MaxChars)
      if ($cut -lt 0) { $cut = $MaxChars }
      $out.Add($remaining.Substring(0, $cut).TrimEnd())
      $remaining = $remaining.Substring($cut).TrimStart()
    }
    if ($remaining.Length -gt 0) { $out.Add($remaining) }
  }

  return ,$out.ToArray()
}

function New-SimplePdf {
  param(
    [string[]]$Lines,
    [string]$Path
  )

  # A4 points.
  $pageWidth = 595
  $pageHeight = 842
  $marginLeft = 50
  $marginTop = 50
  $fontSize = 10
  $leading = 12
  $maxLinesPerPage = [int][math]::Floor(($pageHeight - (2 * $marginTop)) / $leading)

  $pages = New-Object System.Collections.Generic.List[object]
  $current = New-Object System.Collections.Generic.List[string]

  foreach ($l in $Lines) {
    if ($current.Count -ge $maxLinesPerPage) {
      $pages.Add($current.ToArray())
      $current = New-Object System.Collections.Generic.List[string]
    }
    $current.Add($l)
  }
  if ($current.Count -gt 0) { $pages.Add($current.ToArray()) }

  $objects = New-Object System.Collections.Generic.List[byte[]]
  $offsets = New-Object System.Collections.Generic.List[int]

  function Add-Obj([string]$s) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($s)
    $objects.Add($bytes)
  }

  # 1: catalog, 2: pages, 3: font, then for each page: page + content stream
  # We'll fill object references after we know counts.
  Add-Obj "1 0 obj`n<< /Type /Catalog /Pages 2 0 R >>`nendobj`n"
  Add-Obj "2 0 obj`n<< /Type /Pages /Kids [__KIDS__] /Count __COUNT__ >>`nendobj`n"
  Add-Obj "3 0 obj`n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>`nendobj`n"

  $pageObjNums = @()
  $contentObjNums = @()

  $nextObjNum = 4
  for ($i = 0; $i -lt $pages.Count; $i++) {
    $pageObjNums += $nextObjNum
    $contentObjNums += ($nextObjNum + 1)
    $nextObjNum += 2
  }

  for ($i = 0; $i -lt $pages.Count; $i++) {
    $pageNum = $pageObjNums[$i]
    $contentNum = $contentObjNums[$i]

    $pageObj = "$pageNum 0 obj`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] /Resources << /Font << /F1 3 0 R >> >> /Contents $contentNum 0 R >>`nendobj`n"
    Add-Obj $pageObj

    $y = $pageHeight - $marginTop
    $contentLines = New-Object System.Collections.Generic.List[string]
    $contentLines.Add("BT")
    $contentLines.Add("/F1 $fontSize Tf")
    $contentLines.Add("$marginLeft $y Td")
    $contentLines.Add("$leading TL")

    foreach ($line in $pages[$i]) {
      $escaped = Escape-PdfString $line
      $contentLines.Add("($escaped) Tj")
      $contentLines.Add("T*")
    }
    $contentLines.Add("ET")

    $stream = ($contentLines -join "`n") + "`n"
    $streamBytes = [System.Text.Encoding]::ASCII.GetBytes($stream)

    $contentObjHeader = "$contentNum 0 obj`n<< /Length $($streamBytes.Length) >>`nstream`n"
    $contentObjFooter = "endstream`nendobj`n"

    $contentBytes = New-Object byte[] ($([System.Text.Encoding]::ASCII.GetByteCount($contentObjHeader)) + $streamBytes.Length + $([System.Text.Encoding]::ASCII.GetByteCount($contentObjFooter)))
    $pos = 0
    [System.Text.Encoding]::ASCII.GetBytes($contentObjHeader).CopyTo($contentBytes, $pos); $pos += [System.Text.Encoding]::ASCII.GetByteCount($contentObjHeader)
    $streamBytes.CopyTo($contentBytes, $pos); $pos += $streamBytes.Length
    [System.Text.Encoding]::ASCII.GetBytes($contentObjFooter).CopyTo($contentBytes, $pos)

    $objects.Add($contentBytes)
  }

  # Assemble full PDF with xref.
  # Keep header ASCII-only to avoid encoding surprises.
  $header = "%PDF-1.4`n%`n"
  $output = New-Object System.Collections.Generic.List[byte]
  $output.AddRange([System.Text.Encoding]::ASCII.GetBytes($header))

  $offsets.Add(0) | Out-Null # object 0
  for ($i = 0; $i -lt $objects.Count; $i++) {
    $offsets.Add($output.Count) | Out-Null
    $output.AddRange($objects[$i])
  }

  # Patch the Pages object (object 2) with actual kids/count by rebuilding whole file simply:
  # Since we already serialized, simplest is to rebuild from scratch with correct pages.
  # This function is small enough to do a second pass.
  $kids = ($pageObjNums | ForEach-Object { "$_ 0 R" }) -join " "
  $pagesObj = "2 0 obj`n<< /Type /Pages /Kids [$kids] /Count $($pages.Count) >>`nendobj`n"

  # Rebuild all objects with corrected object 2.
  $rebuilt = New-Object System.Collections.Generic.List[byte]
  $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes($header))

  $rebuiltOffsets = New-Object System.Collections.Generic.List[int]
  $rebuiltOffsets.Add(0) | Out-Null

  for ($i = 0; $i -lt $objects.Count; $i++) {
    $rebuiltOffsets.Add($rebuilt.Count) | Out-Null
    if ($i -eq 1) {
      $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes($pagesObj))
    } else {
      $rebuilt.AddRange($objects[$i])
    }
  }

  $xrefStart = $rebuilt.Count
  $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes("xref`n0 $($objects.Count + 1)`n"))
  $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes("0000000000 65535 f `n"))
  for ($i = 1; $i -le $objects.Count; $i++) {
    $off = $rebuiltOffsets[$i]
    $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes(("{0:D10} 00000 n `n" -f $off)))
  }

  $trailer = "trailer`n<< /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xrefStart`n%%EOF`n"
  $rebuilt.AddRange([System.Text.Encoding]::ASCII.GetBytes($trailer))

  [System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
  [System.IO.File]::WriteAllBytes($Path, $rebuilt.ToArray())
}

$here = Split-Path -Parent $PSCommandPath
$root = Split-Path -Parent $here

if ([string]::IsNullOrWhiteSpace($OutFile)) {
  $OutFile = Join-Path $root "dist\\CTF-Writeups.pdf"
}

$writeupFiles = Get-ChildItem -Path $root -Filter "*.md" -File |
  Where-Object { $_.Name -ne "README.md" } |
  Sort-Object Name

$allLines = New-Object System.Collections.Generic.List[string]
$allLines.Add("CTF Writeups Bundle")
$allLines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$allLines.Add("")

foreach ($f in $writeupFiles) {
  $allLines.Add(("=" * 78))
  $allLines.Add($f.Name)
  $allLines.Add(("=" * 78))
  $allLines.Add("")

  $md = Get-Content -Path $f.FullName -Raw
  $lines = Convert-MarkdownToLines -markdown $md
  $wrapped = Wrap-Lines -Lines $lines
  $allLines.AddRange($wrapped)
  $allLines.Add("")
}

New-SimplePdf -Lines $allLines.ToArray() -Path $OutFile
Write-Host "Wrote $OutFile"
