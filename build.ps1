[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MetaEditor,

    [Parameter(Mandatory = $false)]
    [string]$Mql5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Find-MetaEditor {
    $candidates = New-Object System.Collections.Generic.List[string]
    $programRoots = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) }

    foreach ($programRoot in $programRoots) {
        Get-ChildItem -LiteralPath $programRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $candidate = Join-Path $_.FullName 'MetaEditor64.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $candidates.Add((Resolve-Path -LiteralPath $candidate).Path)
            }
        }
    }

    $unique = @($candidates | Sort-Object -Unique)
    if ($unique.Count -eq 1) {
        return $unique[0]
    }

    if ($unique.Count -eq 0) {
        throw 'MetaEditor64.exe nao foi localizado automaticamente. Informe -MetaEditor.'
    }

    $list = $unique -join [Environment]::NewLine
    throw "Mais de um MetaEditor64.exe foi encontrado. Informe -MetaEditor para evitar escolha ambigua:`n$list"
}

function Find-Mql5Root {
    $terminalRoot = Join-Path $env:APPDATA 'MetaQuotes\Terminal'
    if (-not (Test-Path -LiteralPath $terminalRoot -PathType Container)) {
        throw 'Nenhuma pasta de dados MetaQuotes foi localizada. Informe -Mql5.'
    }

    $candidates = Get-ChildItem -LiteralPath $terminalRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $candidate = Join-Path $_.FullName 'MQL5'
        $dialogInclude = Join-Path $candidate 'Include\Controls\Dialog.mqh'
        if (Test-Path -LiteralPath $dialogInclude -PathType Leaf) {
            (Resolve-Path -LiteralPath $candidate).Path
        }
    } | Sort-Object -Unique

    $matches = @($candidates)
    if ($matches.Count -eq 1) {
        return $matches[0]
    }

    if ($matches.Count -eq 0) {
        throw 'Nenhuma raiz MQL5 com Include\Controls\Dialog.mqh foi localizada. Informe -Mql5.'
    }

    $list = $matches -join [Environment]::NewLine
    throw "Mais de uma raiz MQL5 valida foi encontrada. Informe -Mql5 para evitar escolha ambigua:`n$list"
}

function Invoke-MetaEditorCompile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EditorPath,

        [Parameter(Mandatory = $true)]
        [string]$Mql5Root,

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
    $arguments = @(
        "/compile:`"$source`"",
        "/inc:`"$Mql5Root`"",
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
    $mql5Root = Find-Mql5Root
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
    Invoke-MetaEditorCompile -EditorPath $editorPath -Mql5Root $mql5Root -ProjectRoot $projectRoot -RelativeSource $target
}

Write-Host ''
Write-Host 'Build concluido: 0 errors, 0 warnings em todos os alvos.' -ForegroundColor Green
$results | Select-Object Source, Bytes, Ex5 | Format-Table -AutoSize
