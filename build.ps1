[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MetaEditor,

    [Parameter(Mandatory = $false)]
    [string]$Mql5,

    # Nao encadear automaticamente quando o projeto estiver fora da arvore
    # MQL5. O build-linked.ps1 passa este switch ao chamar este script de
    # dentro do vinculo: la o projeto JA esta na arvore, e a guarda so existe
    # para que um encadeamento em laco seja impossivel por construcao.
    [switch]$NoDelegate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'build-paths.ps1')

function Resolve-RequiredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description nao encontrado: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Resolve-RequiredDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Description nao encontrado: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

# Comparacao por PREFIXO DE PASTA, e nao por texto cru: sem a barra final,
# 'C:\MQL5x' passaria por filho de 'C:\MQL5'.
#
# Nao resolve reparse points de proposito. Compilando pelo vinculo que o
# build-linked.ps1 cria, $PSScriptRoot devolve o caminho DO VINCULO — verificado
# em juncao real, nao suposto — e e justamente esse caminho, dentro de Experts,
# que precisa contar como "dentro da arvore". Resolver o alvo devolveria a pasta
# original, fora dela, e o script se encadearia de novo a cada chamada.
function Test-PathUnderRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Child,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $childFull = [IO.Path]::GetFullPath($Child).TrimEnd('\') + '\'
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    return $childFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)
}

# Find-MetaEditor e Find-Mql5RootForEditor moraram aqui ate a Etapa 2b.
# Foram para build-paths.ps1 porque o build-linked.ps1 precisa das mesmas
# respostas para decidir onde criar o vinculo.

function Invoke-MetaEditorCompile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EditorPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$RelativeSource
    )

    $source = Resolve-RequiredFile -Path (Join-Path $ProjectRoot $RelativeSource) -Description 'Fonte'
    $name = [IO.Path]::GetFileNameWithoutExtension($RelativeSource)
    $log = Join-Path $ProjectRoot ("compile_build_" + $name + '.log')
    $ex5 = [IO.Path]::ChangeExtension($source, '.ex5')

    if (Test-Path -LiteralPath $log -PathType Leaf) {
        Remove-Item -LiteralPath $log -Force
    }

    Write-Host ("Compilando {0}..." -f $RelativeSource) -ForegroundColor Cyan
    # NAO passar /inc. Ate o build 6061 ele era inofensivo - apontava para a
    # mesma arvore que o compilador ja usaria. A partir do 6090 ele quebra a
    # compilacao de duas maneiras, e ambas apontam para arquivos da MetaQuotes,
    # o que faz o defeito parecer do ambiente e nao da linha de comando:
    #
    #  1. A BIBLIOTECA PADRAO PARA DE COMPILAR. Include\Canvas\Canvas.mqh
    #     acusa 6 erros dentro do proprio arquivo - "cannot convert parameter
    #     'int' to 'uint&'" em ResourceReadImage/TextGetSize e "wrong parameters
    #     count" em TextOut, este ultimo com o aviso "due to new rules of method
    #     hiding". Sem /inc, o MESMO arquivo compila 0/0.
    #  2. TODO #resource passa a ser recusado com "invalid resource path",
    #     inclusive os res\*.bmp de Include\Controls que a propria MetaQuotes
    #     declara e que existem em disco.
    #
    # Verificado isolando cada caso: um .mq5 de tres linhas que so faz
    # #include <Canvas\Canvas.mqh> reproduz (1), e um que so inclui
    # <Controls\Dialog.mqh> reproduz (2) - com /inc falham, sem /inc passam.
    #
    # Sem /inc o compilador deduz a raiz MQL5 da localizacao do fonte, que e
    # justamente o que o build-linked.ps1 garante ao expor o projeto dentro de
    # Experts. Por isso a raiz continua sendo calculada e conferida acima: ela
    # decide ONDE o projeto e encadeado, nao mais o que vai na linha de comando.
    $arguments = @(
        "/compile:`"$source`"",
        "/log:`"$log`""
    )

    # O ExitCode do MetaEditor nao e confiavel para esta finalidade.
    Start-Process -FilePath $EditorPath -ArgumentList $arguments -Wait -WindowStyle Hidden | Out-Null

    if (-not (Test-Path -LiteralPath $log -PathType Leaf)) {
        throw "MetaEditor nao criou o log esperado: $log"
    }

    $resultMatch = Select-String -LiteralPath $log -Pattern '^Result:' | Select-Object -Last 1
    if ($null -eq $resultMatch) {
        throw "Log sem linha Result: $log"
    }

    $result = $resultMatch.Line
    if ($result -notmatch '^Result:\s+0 errors,\s+0 warnings(?:,|$)') {
        throw "Falha ao compilar $RelativeSource. $result`nLog: $log"
    }

    if (-not (Test-Path -LiteralPath $ex5 -PathType Leaf)) {
        throw "Compilacao informou sucesso, mas o EX5 nao existe: $ex5"
    }

    $item = Get-Item -LiteralPath $ex5
    Write-Host ("  {0}" -f $result) -ForegroundColor Green

    return [pscustomobject]@{
        Source = $RelativeSource
        Result = $result
        Ex5 = $item.FullName
        Bytes = $item.Length
        Log = $log
    }
}

$projectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path

if ([string]::IsNullOrWhiteSpace($MetaEditor)) {
    $editorPath = Find-MetaEditor
}
else {
    $editorPath = Resolve-RequiredFile -Path $MetaEditor -Description 'MetaEditor'
}

if ([string]::IsNullOrWhiteSpace($Mql5)) {
    $mql5Root = Find-Mql5RootForEditor -EditorPath $editorPath
}
else {
    $mql5Root = Resolve-RequiredDirectory -Path $Mql5 -Description 'Raiz MQL5'
}

# Marcador de que a raiz resolvida tem a biblioteca padrao que o projeto USA.
# Era Include\Controls\Dialog.mqh ate a Fase 4; o projeto nao inclui mais
# Controls em lugar nenhum, entao aquele teste passou a confirmar algo
# irrelevante. Canvas\Canvas.mqh e a dependencia real: CanvasRenderer.mqh o
# inclui, e sem ele nenhum alvo do EA compila.
$requiredInclude = Join-Path $mql5Root 'Include\Canvas\Canvas.mqh'
Resolve-RequiredFile -Path $requiredInclude -Description 'Include padrao do MT5' | Out-Null

# O projeto pode estar FORA da arvore MQL5 — e o caso normal aqui, uma pasta por
# versao. Sem /inc (ver Invoke-MetaEditorCompile) o MetaEditor deduz a raiz dos
# includes a partir da PASTA DO FONTE, entao compilar de fora faz o unico include
# de biblioteca padrao do projeto — <Canvas\Canvas.mqh>, em
# UI/Canvas/CanvasRenderer.mqh — nao resolver.
#
# O sintoma engana quem nao conhece o projeto: os tres VisualIndicators passam
# 0/0, porque nenhum deles inclui a biblioteca padrao, e so os dois EAs falham,
# com erros que apontam para arquivos da MetaQuotes. Foi assim que o defeito
# chegou de fora: "o Fusion nao compila".
#
# A checagem do Include logo acima NAO cobre isto: ela confirma que a raiz MQL5
# tem a biblioteca, e nao que o projeto enxerga essa raiz. As duas eram
# confundiveis, e o script chegava a anunciar a raiz certa antes de mandar
# compilar de um lugar de onde ela nao e vista.
if (-not (Test-PathUnderRoot -Child $projectRoot -Root $mql5Root)) {
    if ($NoDelegate) {
        throw ("O projeto esta fora da arvore MQL5 e -NoDelegate foi informado.`n" +
               "  Projeto: $projectRoot`n" +
               "  MQL5:    $mql5Root`n" +
               'Rode build-linked.ps1 para compilar por um vinculo dentro de Experts.')
    }

    $linkedScript = Resolve-RequiredFile -Path (Join-Path $projectRoot 'build-linked.ps1') -Description 'build-linked.ps1'

    Write-Host 'Fusion - build completo' -ForegroundColor White
    Write-Host ("Projeto:    {0}" -f $projectRoot)
    Write-Host ("MQL5:       {0}" -f $mql5Root)
    Write-Host 'O projeto esta fora da arvore MQL5; encadeando por build-linked.ps1.' -ForegroundColor Yellow
    Write-Host ''

    # MetaEditor e raiz vao RESOLVIDOS: redescobrir do zero poderia parar em
    # "mais de um MetaEditor encontrado" mesmo depois de este script ja ter
    # decidido qual usar.
    & $linkedScript -MetaEditor $editorPath -Mql5 $mql5Root
    return
}

$editorItem = Get-Item -LiteralPath $editorPath
Write-Host 'Fusion - build completo' -ForegroundColor White
Write-Host ("Projeto:    {0}" -f $projectRoot)
Write-Host ("MetaEditor: {0}" -f $editorPath)
Write-Host ("Versao:     {0}" -f $editorItem.VersionInfo.ProductVersion)
Write-Host ("MQL5:       {0}" -f $mql5Root)
Write-Host ''

# Cinco alvos. Foram quatro da Fase 4 ate a separacao Demo/Completa, e seis
# durante a transicao da GUI 2.0: o harness Prototype\FusionCanvasPhase1.mq5,
# que compilava o renderizador sozinho, e FusionCanvas.mq5, o mesmo EA com o
# painel em canvas no lugar do classico. Removido o painel antigo, nao ha mais
# dois paineis para comparar nem um renderizador fora do EA.
#
# O quinto alvo e FusionDemo.mq5: o MESMO EA, compilado com FUSION_DEMO_ONLY.
# Nao e uma copia do fonte - e um .mq5 que define o simbolo e inclui os mesmos
# Core/EAEntryPoints.mqh. Por isso os dois entram aqui como alvos irmaos, e
# NENHUM fonte precisa ser editado entre as duas compilacoes.
#
# Os indicadores vem antes dos EAs porque ambos os embutem por #resource:
# compilados depois, os .ex5 carregariam a versao anterior deles.
$targets = @(
    'VisualIndicators\FusionVisualMA.mq5',
    'VisualIndicators\FusionVisualBands.mq5',
    'VisualIndicators\FusionVisualRSI.mq5',
    'Fusion.mq5',
    'FusionDemo.mq5'
)

$results = foreach ($target in $targets) {
    Invoke-MetaEditorCompile -EditorPath $editorPath -ProjectRoot $projectRoot -RelativeSource $target
}

Write-Host ''
Write-Host 'Build concluido: 0 errors, 0 warnings em todos os alvos.' -ForegroundColor Green
$results | Select-Object Source, Bytes, Ex5 | Format-Table -AutoSize
