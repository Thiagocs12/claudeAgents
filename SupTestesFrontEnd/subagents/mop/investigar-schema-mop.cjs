// Script avulso, descartável — investiga colunas de MC_MOP_PRE_OPERACAO e MC_MOP_OPERACAO
// (achadas na varredura anterior) pra montar a consulta de validação pedida pelo Thiago.
require('dotenv').config()
const sql = require('mssql/msnodesqlv8')

const config = {
  server: process.env.HOMOLOG_DB_HOST,
  database: process.env.HOMOLOG_DB_NAME,
  port: Number(process.env.HOMOLOG_DB_PORT),
  driver: 'SQL Server',
  options: { trustedConnection: true, encrypt: false, trustServerCertificate: true },
}

async function main() {
  const pool = await new sql.ConnectionPool(config).connect()
  for (const tabela of ['MC_MOP_PRE_OPERACAO', 'MC_MOP_OPERACAO']) {
    const cols = await pool.request().query(`
      SELECT COLUMN_NAME, DATA_TYPE
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_NAME = '${tabela}'
      ORDER BY ORDINAL_POSITION
    `)
    console.log(`\nCOLUNAS DE ${tabela}:`)
    console.log(JSON.stringify(cols.recordset, null, 2))
  }
  await pool.close()
}

main().catch((err) => {
  console.error('ERRO:', err.message)
  process.exit(1)
})
