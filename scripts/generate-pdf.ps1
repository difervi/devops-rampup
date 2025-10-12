param(
  [string]$SourceFile = "docs\docker-explained.md",
  [string]$OutFile = "docs\docker-explained.pdf"
)

# Script para convertir Markdown a PDF en Windows usando pandoc o wkhtmltopdf
# Uso: pwsh .\scripts\generate-pdf.ps1 -SourceFile docs\docker-explained.md -OutFile docs\docker-explained.pdf

Write-Host "Generando PDF desde:`$SourceFile` -> `$OutFile`"

function ExitWithMessage($code, $msg){
  Write-Host $msg
  exit $code
}

# Check source exists
if (-Not (Test-Path $SourceFile)){
  ExitWithMessage 1 "Archivo fuente no encontrado: $SourceFile"
}

# Prefer pandoc
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if ($pandoc){
  Write-Host "Usando pandoc -> $($pandoc.Source)"
  & pandoc $SourceFile -o $OutFile --pdf-engine=wkhtmltopdf 2>&1 | Write-Host
  if (-Not (Test-Path $OutFile)){
    ExitWithMessage 2 "Pandoc no generó el PDF. Revisa que wkhtmltopdf o LaTeX estén instalados o ejecuta pandoc con --pdf-engine=weasyprint/latex." 
  }
  Write-Host "PDF generado en: $OutFile"
  exit 0
}

# Fallback to wkhtmltopdf if available
$wk = Get-Command wkhtmltopdf -ErrorAction SilentlyContinue
if ($wk){
  Write-Host "Usando wkhtmltopdf -> $($wk.Source)"
  # Convertir Markdown a HTML temporal y luego a PDF
  $tmpHtml = [System.IO.Path]::GetTempFileName() + ".html"
  & pandoc $SourceFile -o $tmpHtml 2>&1 | Write-Host
  & wkhtmltopdf $tmpHtml $OutFile 2>&1 | Write-Host
  Remove-Item $tmpHtml -ErrorAction SilentlyContinue
  if (-Not (Test-Path $OutFile)){
    ExitWithMessage 3 "wkhtmltopdf no generó el PDF." 
  }
  Write-Host "PDF generado en: $OutFile"
  exit 0
}

ExitWithMessage 4 "No se encontró pandoc ni wkhtmltopdf en el PATH. Instala pandoc (recomendado) o wkhtmltopdf y vuelve a ejecutar el script."