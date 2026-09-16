// Script avulso, descartável — validação em banco (somente leitura) pedida pelo Thiago em
// 2026-09-16: confirmar o estado real da(s) operação(ões) de teste em MC_MOP_PRE_OPERACAO /
// MC_MOP_OPERACAO, em vez de confiar só no toast/UI do Beyond Banking.
require('dotenv').config()
const sql = require('mssql/msnodesqlv8')

const config = {
  server: process.env.HOMOLOG_DB_HOST,
  database: process.env.HOMOLOG_DB_NAME,
  port: Number(process.env.HOMOLOG_DB_PORT),
  driver: 'SQL Server',
  options: { trustedConnection: true, encrypt: false, trustServerCertificate: true },
}

const idsParaChecar = process.argv.slice(2).map(Number)

async function main() {
  const pool = await new sql.ConnectionPool(config).connect()
  for (const id of idsParaChecar) {
    const preOp = await pool.request().query(`
      SELECT id, situacao, indVirouOperacao, dataVirouOperacao, indExcluida, indRejeitada,
             dataPreOperacao, dataCadastro, dataUltimaAlteracao
      FROM MC_MOP_PRE_OPERACAO
      WHERE id = ${id}
    `)
    console.log(`\nMC_MOP_PRE_OPERACAO id=${id}:`)
    console.log(JSON.stringify(preOp.recordset, null, 2))

    const op = await pool.request().query(`
      SELECT id, idPreOperacao, situacao, indEfetivada, indRejeitada, dataOperacao, dataCadastro
      FROM MC_MOP_OPERACAO
      WHERE idPreOperacao = ${id}
    `)
    console.log(`MC_MOP_OPERACAO com idPreOperacao=${id}:`)
    console.log(JSON.stringify(op.recordset, null, 2))
  }
  await pool.close()
}

main().catch((err) => {
  console.error('ERRO:', err.message)
  process.exit(1)
})
