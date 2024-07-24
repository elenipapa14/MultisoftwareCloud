
param sqlDatabaseName string = 'multisoftwaresqldb'
param sqlServerName string = 'multisoftwarsqlserver'
@secure()
param administratorLoginPassword string ='SqlDBproject22'
param administratorLogin string ='sqladminname'
param location string = 'northeurope'

// Resource for the SQL database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: '${sqlServerName}/${sqlDatabaseName}'
  tags: {
    Scope: 'Internal'
    Environment: 'Production'
  }
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB // Requires 2-4 GB of storage to meet unpredictable data growth and other needs.
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}


output sqlDatabaseName string = sqlDatabase.name // Quick access to the database name after deployment
