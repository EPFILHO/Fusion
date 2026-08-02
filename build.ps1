[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MetaEditor,

    [Parameter(Mandatory = $false)]
    [string]$Mql5
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

$requiredInclude = Join-Path $mql5Root 'Include\Controls\Dialog.mqh'
Resolve-RequiredFile -Path $requiredInclude -Description 'Include padrao do MT5' | Out-Null

$editorItem = Get-Item -LiteralPath $editorPath
Write-Host 'Fusion - build completo' -ForegroundColor White
Write-Host ("Projeto:    {0}" -f $projectRoot)
Write-Host ("MetaEditor: {0}" -f $editorPath)
Write-Host ("Versao:     {0}" -f $editorItem.VersionInfo.ProductVersion)
Write-Host ("MQL5:       {0}" -f $mql5Root)
Write-Host ''

$targets = @(
    'VisualIndicators\FusionVisualMA.mq5',
    'VisualIndicators\FusionVisualBands.mq5',
    'VisualIndicators\FusionVisualRSI.mq5',
    'Prototype\FusionCanvasPhase1.mq5',
    'Fusion.mq5'
)

$results = foreach ($target in $targets) {
    Invoke-MetaEditorCompile -EditorPath $editorPath -ProjectRoot $projectRoot -RelativeSource $target
}

Write-Host ''
Write-Host 'Build concluido: 0 errors, 0 warnings em todos os alvos.' -ForegroundColor Green
$results | Select-Object Source, Bytes, Ex5 | Format-Table -AutoSize
