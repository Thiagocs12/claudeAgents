// Script reaproveitável (infraestrutura, ver AGENTE.md regra 6) — gera o PDF de relatório de uma
// tarefa a partir do seu arquivo .md e dos screenshots do Cypress. Uso:
//   node scripts/gerar-relatorio-pdf.cjs <id-da-tarefa>
//
// Formato padronizado (pedido do Thiago, 2026-09-18): relatório estilizado, direto ao ponto — uma
// linha curta de ação + o screenshot correspondente, em sequência ("Acessei o portal" [print],
// "Cliquei em Nova Operação" [print], e assim por diante). Não despeja a narrativa bruta de
// "## Execução" (que é o rascunho de trabalho do subAgent, cheio de tentativas/erros) — a
// descrição de cada passo vem do próprio nome do arquivo do screenshot (regra 3 do AGENTE.md já
// pede nomes descritivos tipo "04-apos-selecionar-kenerson-avancar.png"), convertido em frase
// legível. Só "## Resultado" (veredito final) entra como texto corrido, no fim.
const fs = require('fs')
const path = require('path')
const PDFDocument = require('pdfkit')

const idTarefa = process.argv[2]
if (!idTarefa) {
  console.error('Uso: node scripts/gerar-relatorio-pdf.cjs <id-da-tarefa>')
  process.exit(1)
}

const raiz = path.resolve(__dirname, '..')
const pastasTarefas = ['pendentes', 'executando', 'aguardando-resposta', 'aguardando-aprovacao', 'concluidas']
  .map((p) => path.join(raiz, 'tarefas', p, `${idTarefa}.md`))
const caminhoTarefa = pastasTarefas.find((p) => fs.existsSync(p))
if (!caminhoTarefa) {
  console.error(`Arquivo de tarefa nao encontrado para id ${idTarefa} em nenhuma pasta de tarefas/`)
  process.exit(1)
}

const conteudo = fs.readFileSync(caminhoTarefa, 'utf8')

function extrairFrontmatter(texto) {
  const m = texto.match(/^---\n([\s\S]*?)\n---\n/)
  const campos = {}
  if (m) {
    m[1].split('\n').forEach((linha) => {
      const idx = linha.indexOf(':')
      if (idx > -1) campos[linha.slice(0, idx).trim()] = linha.slice(idx + 1).trim()
    })
  }
  return campos
}

function extrairSecao(texto, tituloRegex) {
  const linhas = texto.split('\n')
  let capturando = false
  let buffer = []
  for (const linha of linhas) {
    if (/^## /.test(linha)) {
      if (capturando) break
      if (tituloRegex.test(linha)) {
        capturando = true
        continue
      }
    }
    if (capturando) buffer.push(linha)
  }
  return buffer.join('\n').trim()
}

// Deriva uma legenda legível a partir do nome do arquivo do screenshot — convenção já usada nas
// tarefas (regra 3 do AGENTE.md): "<numero><letra?>-descricao-com-hifens.png".
function legendaDoArquivo(nomeArquivo) {
  const semExtensao = nomeArquivo.replace(/\.png$/i, '')
  const semNumero = semExtensao.replace(/^\d+[a-z]?-/i, '')
  const comEspacos = semNumero.replace(/-/g, ' ').trim()
  if (!comEspacos) return semExtensao
  return comEspacos.charAt(0).toUpperCase() + comEspacos.slice(1)
}

// Ordenação natural pelo prefixo numérico (evita "10-..." vir antes de "2-..." num sort de texto).
function chaveOrdenacao(nomeArquivo) {
  const m = nomeArquivo.match(/^(\d+)([a-z]?)-/i)
  if (!m) return [Number.MAX_SAFE_INTEGER, nomeArquivo]
  return [Number(m[1]), m[2] || '']
}

const frontmatter = extrairFrontmatter(conteudo)
const objetivo = extrairSecao(conteudo, /^## Objetivo/)
const resultado = extrairSecao(conteudo, /^## Resultado/)

const pastaScreenshots = path.join(raiz, 'cypress', 'screenshots')
let screenshots = []
if (fs.existsSync(pastaScreenshots)) {
  const percorrer = (dir) => {
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, item.name)
      if (item.isDirectory()) percorrer(p)
      else if (/\.png$/i.test(item.name)) screenshots.push(p)
    }
  }
  percorrer(pastaScreenshots)
  screenshots.sort((a, b) => {
    const [na, la] = chaveOrdenacao(path.basename(a))
    const [nb, lb] = chaveOrdenacao(path.basename(b))
    return na - nb || la.localeCompare(lb)
  })
}

const pastaRelatorios = path.join(raiz, 'relatorios')
fs.mkdirSync(pastaRelatorios, { recursive: true })
const caminhoPdf = path.join(pastaRelatorios, `${idTarefa}.pdf`)

// --- Paleta e constantes visuais ---
const COR_PRIMARIA = '#1f3a5f'
const COR_TEXTO_CLARO = '#ffffff'
const COR_CINZA = '#6b7280'
const COR_LINHA = '#d0d5dd'
const MODULO = frontmatter.modulo || '(não informado)'

const doc = new PDFDocument({ margin: 50, bufferPages: true })
doc.pipe(fs.createWriteStream(caminhoPdf))

function desenharCabecalho(titulo) {
  doc.rect(0, 0, doc.page.width, 70).fill(COR_PRIMARIA)
  doc.fillColor(COR_TEXTO_CLARO).fontSize(14).font('Helvetica-Bold')
    .text(titulo, 50, 25, { width: doc.page.width - 100 })
  doc.fillColor('black').font('Helvetica')
}

function desenharRodape(numeroPagina) {
  const y = doc.page.height - 40
  doc.moveTo(50, y).lineTo(doc.page.width - 50, y).strokeColor(COR_LINHA).lineWidth(0.5).stroke()
  doc.fontSize(8).fillColor(COR_CINZA)
    .text(`Módulo: ${MODULO} — ${idTarefa}`, 50, y + 8, { continued: false })
  doc.text(`${numeroPagina}`, doc.page.width - 100, y + 8, { width: 50, align: 'right' })
  doc.fillColor('black')
}

// --- Capa ---
doc.rect(0, 0, doc.page.width, 160).fill(COR_PRIMARIA)
doc.fillColor(COR_TEXTO_CLARO).fontSize(22).font('Helvetica-Bold')
  .text('Relatório de Teste Exploratório', 50, 55, { align: 'center' })
doc.fontSize(13).font('Helvetica').text('Sup TestesFrontEnd', { align: 'center' })
doc.fillColor('black')
doc.moveDown(4)

const linhaMeta = (rotulo, valor) => {
  doc.fontSize(11).font('Helvetica-Bold').text(`${rotulo}: `, { continued: true })
  doc.font('Helvetica').text(valor)
}
doc.moveDown(1)
linhaMeta('Módulo', MODULO)
linhaMeta('Id da tarefa', idTarefa)
linhaMeta('Data da tarefa', frontmatter.data || '(não informado)')
linhaMeta('Solicitado por', frontmatter.solicitado_por || '(não informado)')
linhaMeta('Gerado em', new Date().toLocaleString('pt-BR'))
doc.moveDown(1.5)
doc.fontSize(13).font('Helvetica-Bold').fillColor(COR_PRIMARIA).text('Objetivo')
doc.fillColor('black').font('Helvetica').fontSize(11).moveDown(0.3)
doc.text(objetivo || '(sem objetivo registrado)')

// --- Passo a passo (uma ação + screenshot por página) ---
if (screenshots.length > 0) {
  screenshots.forEach((screenshot, i) => {
    doc.addPage()
    desenharCabecalho('Passo a passo da execução')
    doc.moveDown(4)
    doc.fontSize(9).fillColor(COR_PRIMARIA).font('Helvetica-Bold')
      .text(`PASSO ${i + 1} DE ${screenshots.length}`)
    doc.fillColor('black').fontSize(13).font('Helvetica-Bold').moveDown(0.2)
    doc.text(legendaDoArquivo(path.basename(screenshot)))
    doc.moveDown(0.5)
    const yImagem = doc.y
    const alturaDisponivel = doc.page.height - yImagem - 60
    try {
      doc.image(screenshot, {
        fit: [doc.page.width - 100, alturaDisponivel],
        align: 'center',
      })
    } catch (e) {
      doc.fontSize(10).fillColor(COR_CINZA).text(`(falha ao inserir imagem: ${e.message})`)
    }
  })
}

// --- Resultado ---
doc.addPage()
desenharCabecalho('Resultado')
doc.moveDown(4)
doc.fontSize(11).fillColor('black').text(resultado || '(sem resultado registrado ainda)')

// --- Rodapé em todas as páginas (numeração real, via bufferPages) ---
const totalPaginas = doc.bufferedPageRange().count
for (let i = 0; i < totalPaginas; i++) {
  doc.switchToPage(i)
  desenharRodape(i + 1)
}

doc.end()
console.log(`PDF gerado em ${caminhoPdf}`)
