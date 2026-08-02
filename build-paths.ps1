# Descoberta de MetaEditor e da raiz MQL5 correspondente.
#
# Vive num arquivo proprio porque build.ps1 e build-linked.ps1 precisam da
# MESMA resposta: o primeiro para compilar, o segundo para decidir onde criar o
# vinculo. Duas copias divergiriam, e a divergencia apareceria como um build que
# funciona por um caminho e falha pelo outro — que foi exatamente o sintoma que
# levou a este arquivo existir.

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

# A raiz MQL5 tem de ser A DO PROPRIO MetaEditor escolhido, e nao uma qualquer
# que contenha o Include padrao. Esta funcao substitui uma versao que aceitava
# qualquer pasta de dados valida — e que, com 28 delas na maquina, so sabia
# desistir e pedir -Mql5.
#
# Por que o pareamento importa: sem /inc (ver Invoke-MetaEditorCompile) o
# compilador resolve os #resource iniciados por "\" contra A SUA pasta de dados.
# Compilando a partir de outra, os tres #resource dos VisualIndicators falham
# com "invalid resource path" — o arquivo existe, mas nao na arvore que o
# compilador considera sua.
#
# O vinculo instalacao -> pasta de dados esta em origin.txt, que o terminal
# grava com o caminho da instalacao. E a mesma associacao que o MetaEditor usa,
# entao casar por ela nao e heuristica: e ler a resposta pronta.
function Find-Mql5RootForEditor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EditorPath
    )

    $installDir = (Split-Path -Parent $EditorPath).TrimEnd('\')
    $terminalRoot = Join-Path $env:APPDATA 'MetaQuotes\Terminal'
    if (-not (Test-Path -LiteralPath $terminalRoot -PathType Container)) {
        throw 'Nenhuma pasta de dados MetaQuotes foi localizada. Informe -Mql5.'
    }

    $found = Get-ChildItem -LiteralPath $terminalRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $originFile = Join-Path $_.FullName 'origin.txt'
        if (-not (Test-Path -LiteralPath $originFile -PathType Leaf)) {
            return
        }
        $origin = Get-Content -LiteralPath $originFile -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($origin)) {
            return
        }
        if ($origin.Trim().TrimEnd('\') -ne $installDir) {
            return
        }
        $candidate = Join-Path $_.FullName 'MQL5'
        if (Test-Path -LiteralPath (Join-Path $candidate 'Include\Controls\Dialog.mqh') -PathType Leaf) {
            (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $matched = @($found | Sort-Object -Unique)
    if ($matched.Count -ge 1) {
        return $matched[0]
    }

    throw ("Nenhuma pasta de dados corresponde a instalacao '{0}'. " -f $installDir) +
          'Abra o terminal uma vez para ele criar a pasta, ou informe -Mql5.'
}
