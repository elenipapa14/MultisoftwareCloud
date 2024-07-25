// Set our defined location of North Europe, for data regulation reasons.
param location string = 'northeurope'
param cosmosDbAccountName string = 'multisoftwarecosmosdb'
param databaseName string = 'multiSoftwareDatabase'
// Setting a throughput that will be enough for the database requirements.
param throughput int = 1000
// Setting a name for the key vault that will store the database token after it is created.
param keyVaultName string = 'vault563224'


resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: {
   Scope: 'Internal'
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479'
        permissions: {
          secrets: ['get', 'list', 'set']
        }
      }
    ]
  }
}


resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  tags: {
   Scope: 'Internal'
   Environment: 'Production'
  }
  properties: {
    databaseAccountOfferType: 'Standard' 
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    consistencyPolicy: {
      // Balances performance and consistency
      defaultConsistencyLevel: 'Session' 
    }
  }
}

resource cosmosDbSqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosDbAccount
  name: databaseName
  tags: {
   Scope: 'Internal'
   Environment: 'Production'
  }
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: throughput
    }
  }
}

resource cosmosDbSqlContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDbSqlDatabase
  name: 'multiSoftwareContainer'
  tags: {
   Scope: 'Internal'
   Environment: 'Production'
  }
  properties: {
    resource: {
      id: 'multiSoftwareContainer'
      partitionKey: {
        paths: [
         // Defines the partition key path, which is necessary for distributing data across partitions.
          '/partitionKey' 
        ]
        kind: 'Hash'
      }
      // Handles the indexing policy for the container
      indexingPolicy: { 
         // Indexing is automatic and will be updated with the creation or updating of data.
         // The 'lazy' alternative leads to delays in indexing and 'none' deactivates it.
        indexingMode: 'consistent'
        // Indexing is automatic and requires no extra settings set by the user.
        automatic: true 
      }
    }
    options: {}
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'cosmosDbPrimaryKey'
  properties: {
    value: cosmosDbAccount.listKeys().primaryMasterKey
  }
}

output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
