// Parameter declarations
param sqlServerName string = 'multisoftwarsqlserver'
param administratorLogin string ='sqladminname'
@secure()
param administratorLoginPassword string ='SqlDBproject22'
param location string = 'northeurope'

// Resource for the SQL server
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    Scope: 'Internal'
    Environment: 'Production'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  sku: {
    name: 'S1'
    tier: 'Standard' //Balance between performance and cost,suitable for many production applications
  }
}


// Output the SQL Server details
output sqlServerName string = sqlServer.name //quick access to SQL Server name after deployment.
output sqlServerAdminLogin string = administratorLogin //quick access to admin username after deployment.