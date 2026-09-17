// Script reaproveitável (infraestrutura, ver AGENTE.md regra 6) — gera o PDF de relatório de uma
// tarefa a partir do seu arquivo .md (capa + narrativa "## Execução" + screenshots do cypress +
// "## Resultado"). Uso: node scripts/gerar-relatorio-pdf.cjs <id-da-tarefa>
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

function extrairTodasSecoesExecucao(texto) {
  const linhas = texto.split('\n')
  const secoes = []
  let atual = null
  for (const linha of linhas) {
    if (/^## Execu/.test(linha)) {
      if (atual) secoes.push(atual)
      atual = { titulo: linha.replace(/^##\s*/, ''), corpo: [] }
      continue
    }
    if (/^## Resultado/.test(linha)) {
      if (atual) secoes.push(atual)
      atual = null
      continue
    }
    if (atual) atual.corpo.push(linha)
  }
  if (atual) secoes.push(atual)
  return secoes.map((s) => ({ titulo: s.titulo, corpo: s.corpo.join('\n').trim() }))
}

const frontmatter = extrairFrontmatter(conteudo)
const objetivo = extrairSecao(conteudo, /^## Objetivo/)
const resultado = extrairSecao(conteudo, /^## Resultado/)
const secoesExecucao = extrairTodasSecoesExecucao(conteudo)

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
  screenshots.sort((a, b) => path.basename(a).localeCompare(path.basename(b)))
}

const pastaRelatorios = path.join(raiz, 'relatorios')
fs.mkdirSync(pastaRelatorios, { recursive: true })
const caminhoPdf = path.join(pastaRelatorios, `${idTarefa}.pdf`)

const doc = new PDFDocument({ margin: 50 })
doc.pipe(fs.createWriteStream(caminhoPdf))

// Capa
doc.fontSize(20).text('Relatório de Teste Exploratório — Sup TestesFrontEnd', { align: 'center' })
doc.moveDown()
doc.fontSize(14).text(`Módulo: ${frontmatter.modulo || '(não informado)'}`)
doc.text(`Id da tarefa: ${idTarefa}`)
doc.text(`Data da tarefa: ${frontmatter.data || '(não informado)'}`)
doc.text(`Solicitado por: ${frontmatter.solicitado_por || '(não informado)'}`)
doc.text(`Gerado em: ${new Date().toISOString()}`)
doc.moveDown()
doc.fontSize(13).text('Objetivo', { underline: true })
doc.moveDown(0.5)
doc.fontSize(11).text(objetivo || '(sem objetivo registrado)')

// Narrativa
for (const secao of secoesExecucao) {
  doc.addPage()
  doc.fontSize(14).text(secao.titulo, { underline: true })
  doc.moveDown(0.5)
  doc.fontSize(10).text(secao.corpo || '(sem narrativa registrada)')
}

// Screenshots (apendice, em ordem — evidencia visual das tentativas)
if (screenshots.length > 0) {
  doc.addPage()
  doc.fontSize(14).text('Apêndice — Screenshots (em ordem)', { underline: true })
  for (const screenshot of screenshots) {
    doc.addPage()
    doc.fontSize(9).fillColor('gray').text(path.basename(screenshot))
    doc.fillColor('black')
    try {
      doc.image(screenshot, { fit: [500, 650], align: 'center' })
    } catch (e) {
      doc.fontSize(10).text(`(falha ao inserir imagem: ${e.message})`)
    }
  }
}

// Resultado
doc.addPage()
doc.fontSize(14).text('Resultado', { underline: true })
doc.moveDown(0.5)
doc.fontSize(11).text(resultado || '(sem resultado registrado ainda)')

doc.end()
console.log(`PDF gerado em ${caminhoPdf}`)
