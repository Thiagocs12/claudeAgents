# Executado pela Scheduled Task "SupAutomacaoUteis-SubAgent-cedente" a cada 5 minutos.
# Roda um único ciclo do subAgent do módulo "cedente" em modo não interativo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# Conta do Claude Code dedicada a este subAgent (2º módulo criado -> contaB).
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"

# Checagem determinística (sem custo de chamada ao Claude) do que a Scheduled Task faria via LLM
# nos passos 1-4 da seção 3.2 do CLAUDE.md: só vale a pena chamar `claude -p` se houver algo
# pendente, retomável, ou uma dúvida já respondida esperando voltar pra fila. Ver seção
# "Pré-checagem em PowerShell antes de chamar claude -p" do CLAUDE.md.
function Test-DuvidaRespondida {
    param([string]$DuvidasPath, [string]$Id)
    if (-not (Test-Path $DuvidasPath)) { return $false }
    $conteudo = Get-Content $DuvidasPath -Raw -ErrorAction SilentlyContinue
    if (-not $conteudo) { return $false }
    foreach ($bloco in [regex]::Split($conteudo, '(?m)^##\s+')) {
        if ($bloco -match "^$([regex]::Escape($Id))\s*(\r?\n|$)") {
            return [bool]($bloco -match '(?m)^Status:\s*respondida\s*$')
        }
    }
    return $false
}

function Test-TrabalhoPendente {
    $temPendente = (Get-ChildItem -Path "tarefas/pendentes" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($temPendente) { return $true }

    $temExecutando = (Get-ChildItem -Path "tarefas/executando" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($temExecutando) { return $true }

    $aguardando = Get-ChildItem -Path "tarefas/aguardando-resposta" -File -ErrorAction SilentlyContinue
    foreach ($arquivo in $aguardando) {
        $id = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
        if (Test-DuvidaRespondida -DuvidasPath "duvidas.md" -Id $id) { return $true }
    }
    return $false
}

if (-not (Test-TrabalhoPendente)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] sem tarefa pendente/retomavel/respondida - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o SubAgent do módulo "cedente" (automação utilitária). Leia AGENTE.md nesta pasta e siga
suas regras fixas à risca. Execute agora UM único ciclo da lógica operacional:

1. Em tarefas/aguardando-resposta/: para cada tarefa cuja dúvida correspondente em duvidas.md já
   esteja "Status: respondida", mova o arquivo de volta para tarefas/pendentes/.
2. Se tarefas/executando/ já tiver uma tarefa, RETOME-A (um ciclo anterior pode ter esgotado antes
   de terminar, o que é esperado numa tarefa deste tamanho): procure em repo/ uma branch já criada
   para essa tarefa (nome derivado do id/slug); se existir, dê checkout nela e continue a
   implementação de onde parou (não recomece do zero, não descarte trabalho já feito); se não
   houver nenhuma branch/progresso, trate como se estivesse começando agora. Prossiga a partir do
   passo 5.
3. Se tarefas/executando/ estiver vazia e houver algo em tarefas/pendentes/, mova a mais antiga
   (pelo timestamp no nome do arquivo) para tarefas/executando/ e prossiga.
4. Se não houver nada a fazer nos passos 1-3 (nem retomar, nem iniciar), encerre o ciclo agora.
5. Leia ../../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro.
6. No repositório em repo/: se está começando a tarefa agora, dê pull na branch reviewAgents e crie
   uma branch nova para ela; se está retomando (passo 2), não refaça pull/checkout, continue na
   branch existente. Implemente a tarefa conforme o escopo definido no arquivo da tarefa e a regra
   2 do AGENTE.md (ler e seguir o padrão do README.md/CLAUDE.md do repo, atualizando-os se
   necessário). Reaproveite a infraestrutura já existente (cy.definirAmbiente, cy.obterToken,
   cy.executarQuery/dbClient.cjs para SQL Server, o padrão de resolução de dependências PROD→HML já
   usado em Produtos/Esteiras/Vínculos para tabelas de catálogo/domínio) — não reimplemente essas
   partes do zero. Dado o tamanho da tarefa, é esperado e correto dividir em commits incrementais
   (uma etapa do ciclo prospect→cedente por vez) ao longo de vários ciclos — commit o progresso
   parcial funcional antes do ciclo esgotar, nunca deixe só em arquivos não commitados.
7. Rode um autoteste sobre sua própria implementação antes de considerar concluído (npm run lint,
   npm run test:safety, e o cenário/tag da tarefa via npx cypress run --env tags=<tag> quando a
   etapa implementada já permitir um teste fim a fim).
8. Se concluir com sucesso: siga a regra 7 do AGENTE.md (commit + push da branch, aviso em
   ../../agent-master/fila-merge/pendentes/ com a branch e o id da tarefa — o Agent Master faz o
   merge direto na reviewAgents depois de rodar os testes, sem PR por tarefa — atualize
   docs/documentacao.md e, se o aprendizado valer para qualquer módulo, também
   ../../docs/conhecimento-geral.md, mova o arquivo de tarefas/executando/ para
   tarefas/concluidas/).
9. Se travar numa dúvida bloqueante — inclusive qualquer decisão sobre incluir uma tabela fora do
   escopo já definido na tarefa, ou sobre a ordem/segurança do DELETE em HML: siga a regra 8 do
   AGENTE.md (registre em duvidas.md no formato padrão, mova o arquivo de tarefas/executando/ para
   tarefas/aguardando-resposta/, e encerre o ciclo sem terminar a tarefa). Nunca responda sua
   própria dúvida. Nunca decida sozinho um desses pontos sensíveis.

Nunca trabalhe em mais de uma tarefa ativa por vez. Nunca exponha credencial/token/senha em
docs/documentacao.md, duvidas.md, log, ou no aviso pro Agent Master. Produção é somente leitura —
DELETE só é permitido contra HML, um cedente por vez, respeitando a ordem de dependência das
foreign keys.
'@

$prompt | claude -p --permission-mode bypassPermissions --output-format stream-json --verbose 2>&1 |
    ForEach-Object {
        $linha = $_.ToString()
        $ts = Get-Date -Format "HH:mm:ss"
        $texto = $null
        try {
            $evt = $linha | ConvertFrom-Json -ErrorAction Stop
            switch ($evt.type) {
                "system" { $texto = "[sessao] modelo=$($evt.model) cwd=$($evt.cwd)" }
                "assistant" {
                    foreach ($bloco in $evt.message.content) {
                        if ($bloco.type -eq "text" -and $bloco.text) {
                            $texto = "[fala] $($bloco.text)"
                        } elseif ($bloco.type -eq "tool_use") {
                            $args = ($bloco.input | ConvertTo-Json -Compress -Depth 4)
                            if ($args.Length -gt 300) { $args = $args.Substring(0, 300) + "..." }
                            $texto = "[tool] $($bloco.name) $args"
                        }
                    }
                }
                "user" {
                    foreach ($bloco in $evt.message.content) {
                        if ($bloco.type -eq "tool_result") {
                            $conteudo = if ($bloco.content -is [array]) {
                                ($bloco.content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text
                            } else { $bloco.content }
                            if ($conteudo) {
                                if ($conteudo.Length -gt 300) { $conteudo = $conteudo.Substring(0, 300) + "..." }
                                $texto = "[resultado] $conteudo"
                            }
                        }
                    }
                }
                "result" { $texto = "[ciclo encerrado] $($evt.subtype) duracao=$($evt.duration_ms)ms custo=`$$($evt.total_cost_usd)" }
            }
        } catch {}
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }
