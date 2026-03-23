$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

Describe "CTF writeups" {
  It "contains 5-10 writeup markdown files" {
    $writeups = Get-ChildItem -Path $root -Filter "*.md" -File |
      Where-Object { $_.Name -ne "README.md" }
    $writeups.Count | Should BeGreaterThan 4
    $writeups.Count | Should BeLessThan 11
  }

  It "each writeup has required metadata and footer" {
    $writeups = Get-ChildItem -Path $root -Filter "*.md" -File |
      Where-Object { $_.Name -ne "README.md" }

    foreach ($w in $writeups) {
      $text = Get-Content -Path $w.FullName -Raw

      # Minimal front-matter checks (YAML-ish).
      $text | Should Match '(?ms)^---\s*\r?\n.+?\r?\n---\s*\r?\n'
      $text | Should Match '(?m)^title:\s*".+"\s*$'
      $text | Should Match '(?m)^category:\s*".+"\s*$'
      $text | Should Match '(?m)^difficulty:\s*"(Easy|Medium|Hard)"\s*$'
      $text | Should Match '(?m)^tags:\s*\[.+\]\s*$'
      $text | Should Match '(?m)^challenge:\s*"challenges/.+"\s*$'
      $text | Should Match '(?m)^exploit:\s*"exploits/.+"\s*$'
      $text | Should Match '(?m)^last_updated:\s*"\d{4}-\d{2}-\d{2}"\s*$'

      # Footer presence (ethics note).
      $text | Should Match '(?ms)---\s*\r?\nEthics note: .+permission to test\.'
    }
  }

  It "README index references all writeups with difficulty and tags" {
    $readmePath = Join-Path $root "README.md"
    $readme = Get-Content -Path $readmePath -Raw

    # Collect writeups from filesystem.
    $writeups = Get-ChildItem -Path $root -Filter "*.md" -File |
      Where-Object { $_.Name -ne "README.md" } |
      Sort-Object Name

    foreach ($w in $writeups) {
      $pattern = [regex]::Escape("[$($w.Name)]($($w.Name))")
      $readme | Should Match $pattern
    }

    # Ensure index includes Difficulty and Tags columns.
    $readme | Should Match "\\|\\s*#\\s*\\|\\s*Title\\s*\\|\\s*Difficulty\\s*\\|\\s*Tags\\s*\\|"

    # Quick sanity on difficulty values.
    $readme | Should Match '\|\s*\d+\s*\|.+\|\s*(Easy|Medium|Hard)\s*\|\s*`.+`\s*,'
  }
}
