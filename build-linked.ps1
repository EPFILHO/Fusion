[CmdletBinding()]
param(
    # Ambos opcionais: omitidos, sao descobertos por build-paths.ps1, e a raiz
    # MQL5 sai PAREADA com o MetaEditor escolhido (via origin.txt).
    #
    # Eram obrigatorios ate a Etapa 2b, e informar a raiz errada era facil:
    # existem dezenas de pastas de dados na maquina e todas parecem validas.
    # Escolher uma que nao fosse a do MetaEditor fazia os #resource do Fusion.mq5
    # falharem com "invalid resource path" - erro que aponta para o projeto e
    # nao para o argumento, e por isso custa caro para diagnosticar.
    [Parameter(Mandatory = $false)]
    [string]$MetaEditor,

    [Parameter(Mandatory = $false)]
    [string]$Mql5,

    # Mantem o vinculo apos compilar. Util para abrir o projeto no MetaEditor
    # pelo caminho que o compilador aceita.
    [switch]$KeepLink
)

# A partir do MetaEditor 5.0.0.6061 o compilador exige que os arquivos de
# #resource resolvam dentro da arvore MQL5. Este projeto vive fora dela, uma
# pasta por versao, e essa organizacao deve continuar.
#
# A solucao e expor a pasta da versao atual dentro de MQL5\Experts por um
# vinculo de diretorio, compilar por esse caminho e remove-lo em seguida.
#
# Vinculo e nao copia de proposito: uma copia cria um segundo projeto que pode
# ficar defasado, e um build silenciosamente antigo ja custou um teste inteiro
# nesta sessao. Com o vinculo existe um unico projeto, e os .ex5 nascem
# direto na pasta da versao. Para trocar por copia, bastaria substituir o
# mklink por Copy-Item e trazer os .ex5 de volta no final.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'build-paths.ps1')

$projectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$versionName = Split-Path -Leaf $projectRoot

if ([string]::IsNullOrWhiteSpace($MetaEditor)) {
    $MetaEditor = Find-MetaEditor
}
if (-not (Test-Path -LiteralPath $MetaEditor -PathType Leaf)) {
    throw "MetaEditor nao encontrado: $MetaEditor"
}

# A raiz precisa ser a do MetaEditor acima: e nela que o compilador resolve os
# #resource, e e nela que o vinculo tem de nascer para o projeto ser visto.
if ([string]::IsNullOrWhiteSpace($Mql5)) {
    $Mql5 = Find-Mql5RootForEditor -EditorPath (Resolve-Path -LiteralPath $MetaEditor).Path
}
if (-not (Test-Path -LiteralPath $Mql5 -PathType Container)) {
    throw "Raiz MQL5 nao encontrada: $Mql5"
}

$stageRoot = Join-Path $Mql5 'Experts\FusionBuild'
$linkPath  = Join-Path $stageRoot $versionName

if (-not (Test-Path -LiteralPath $stageRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
}

# Um vinculo remanescente de uma execucao interrompida apontaria para a pasta
# errada; sempre recriamos.
if (Test-Path -LiteralPath $linkPath) {
    cmd /c rmdir "$linkPath" | Out-Null
}

Write-Host ("Vinculando {0} -> {1}" -f $versionName, $linkPath) -ForegroundColor Cyan
cmd /c mklink /J "$linkPath" "$projectRoot" | Out-Null
if (-not (Test-Path -LiteralPath $linkPath)) {
    throw "Nao foi possivel criar o vinculo em $linkPath"
}

try {
    & (Join-Path $linkPath 'build.ps1') -MetaEditor $MetaEditor -Mql5 $Mql5
}
finally {
    if ($KeepLink) {
        Write-Host ("Vinculo mantido: {0}" -f $linkPath) -ForegroundColor Yellow
    }
    else {
        cmd /c rmdir "$linkPath" | Out-Null
        # rmdir em junction remove apenas o vinculo; o projeto permanece.
        Write-Host 'Vinculo removido.' -ForegroundColor DarkGray
    }
}
