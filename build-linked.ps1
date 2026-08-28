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

# Remocao de vinculo, e SO de vinculo. Unico ponto do script que apaga alguma
# coisa: os dois lugares que precisam disso — o remanescente de uma execucao
# interrompida e a limpeza do `finally` — passam por aqui, para nao existirem
# duas regras capazes de divergir.
#
# Por que nao `Remove-Item`: no PowerShell 5.1 ele tem historico de atravessar o
# reparse point e apagar o conteudo do ALVO, que aqui seria o repositorio.
# Por que nao `cmd /c rmdir`: funciona e nao tem esse defeito, mas devolve so um
# codigo de saida, sem deixar checar nada antes nem depois no mesmo lugar.
# `[IO.Directory]::Delete` com recurse desligado remove a ENTRADA de diretorio —
# o vinculo — sem atravessar para o alvo, e fica no meio das checagens.
#
# Criar continua por `mklink /J`: e o mecanismo ja provado, e criar nao carrega o
# risco que remover carrega.
function Remove-FusionJunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $item = Get-Item -LiteralPath $Path -Force

    if (-not ($item.PSIsContainer)) {
        throw ("Existe um ARQUIVO onde o vinculo deveria estar, e ele nao sera removido:`n" +
               "  $Path")
    }

    if ((($item.Attributes) -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
        throw ("Existe um DIRETORIO COMUM onde o vinculo deveria estar, e ele nao sera removido:`n" +
               "  $Path`n" +
               'Mova ou renomeie esse item e rode de novo.')
    }

    [IO.Directory]::Delete($Path, $false)

    if (Test-Path -LiteralPath $Path) {
        throw "Nao foi possivel remover o vinculo: $Path"
    }
}

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
#
# Agora que o build.ps1 chama este script sozinho, um caminho com o nome da
# versao pode existir sem ter sido criado aqui — uma copia manual do projeto,
# por exemplo. Por isso a remocao passa por Remove-FusionJunction, que se recusa
# a apagar o que nao for vinculo.
Remove-FusionJunction -Path $linkPath

Write-Host ("Vinculando {0} -> {1}" -f $versionName, $linkPath) -ForegroundColor Cyan
cmd /c mklink /J "$linkPath" "$projectRoot" | Out-Null
if (-not (Test-Path -LiteralPath $linkPath)) {
    throw "Nao foi possivel criar o vinculo em $linkPath"
}

try {
    # -NoDelegate: daqui de dentro o projeto ja esta na arvore MQL5, entao o
    # build.ps1 nao teria por que encadear. O switch torna um laco impossivel
    # por construcao, em vez de depender de a checagem de caminho acertar.
    & (Join-Path $linkPath 'build.ps1') -MetaEditor $MetaEditor -Mql5 $Mql5 -NoDelegate
}
finally {
    if ($KeepLink) {
        Write-Host ("Vinculo mantido: {0}" -f $linkPath) -ForegroundColor Yellow
    }
    else {
        # Remove apenas o vinculo; o projeto permanece onde esta.
        Remove-FusionJunction -Path $linkPath
        Write-Host 'Vinculo removido.' -ForegroundColor DarkGray
    }
}
