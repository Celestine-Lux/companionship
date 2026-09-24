param(
  [int]$Port = 3000
)

$env:PORT = $Port
node (Join-Path $PSScriptRoot 'server.js')
