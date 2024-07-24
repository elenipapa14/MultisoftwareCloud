param location string = 'northeurope' //Καθορισμένη τοποθεσία
param cosmosDbAccountName string = 'multisoftwarecosmosdb'
param databaseName string = 'multiSoftwareDatabase'
param throughput int = 400 //μας αρκεί το default 400, ακριβώς θέλουμε 188- Σημειώσεις trello req 7
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
    databaseAccountOfferType: 'Standard' //Η πιο κοινή επιλογή, χρησιμοποιείται για λογαριασμούς που υποστηρίζουν τη διαχείριση της κλίμακας της αποδοτικότητας μέσω προμήθειας RUs (Request Units).
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session' // balances performance and consistency
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
          '/partitionKey' //Defines the partition key path, which is necessary for distributing data across partitions.
        ]
        kind: 'Hash'
      }
      indexingPolicy: { //Ορίζει την πολιτική ευρετηρίασης για τον container.
        indexingMode: 'consistent' //η ευρετηρίαση θα γίνεται αυτόματα και θα ενημερώνεται κάθε φορά που εισάγονται ή ενημερώνονται δεδομένα.
                                   // οι άλλες επιλογές είναι lazy οδηγεί σε καθυστερήσεις στην ευρετηρίαση των δεδομένων και none=απεργοποίηση ευρετηρίασης
        automatic: true //η ευρετηρίαση θα γίνεται αυτόματα χωρίς την ανάγκη για επιπλέον ρυθμίσεις από τον χρήστη.
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
