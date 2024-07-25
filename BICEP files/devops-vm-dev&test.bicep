// Parameters
param location string = 'northeurope' //Defined-Selected Region
param vmAdminUsername string
@secure()
param vmAdminPassword string

// Variables
var devVmCount = 100
var testVmCount = 30
var devVmSize = 'Standard_D4s_v3' //vCPUs: 4, RAM: 16 GB, Storage: Premium SSD, Suitable for development and testing
var testVmSize = 'Standard_B2s'   //vCPUs: 2, RAM: 4 GB, Storage: Standard SSD, stronger than Standard_B1ms, suitable if more resources are needed for testing
var devEnvironmentNamePrefix = 'devEnv' 
var testEnvironmentNamePrefix = 'testEnv' 
var storageAccountName = 'devopsstorage657336' 
var shareNameTest = 'commonsharetest'

// Resource: Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'devops_networking' 
  location: location 
  tags: {  //the appropriate tags, corresponding to our split  
    Scope: 'Internal'
    Environment: 'Production'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24' //CIDR Block, Suitable for infrastructures with hundreds or thousands of resources
      ]
    }
    subnets: [
      {
        name: 'subnet-devops'
        properties: {
          addressPrefix: '10.0.0.0/24' 
        }
      }
    ]
  }
}

// Resource: Storage Account for Test Environments
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: { //the appropriate tags
    Scope: 'Internal'
    Environment: 'Production'
  }
  sku: {
    name: 'Standard_LRS' //Low cost, local replication
  }
  kind: 'StorageV2'
  properties: {}
}

resource fileServiceTest 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    // properties for file service if needed
  }
} 

// Resource: File Share for Test VMs
resource fileShareTest 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  parent: fileServiceTest
  name: shareNameTest
  properties: {
    accessTier: 'TransactionOptimized' //χρήση του tier TransactionOptimized: Για εφαρμογές που εκτελούν συχνές αναγνώσεις και εγγραφές. 
  }
}

// Development VMs
resource devVms 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(0, devVmCount): {
  name: '${devEnvironmentNamePrefix}${i}'
  location: location
  tags: { //the appropriate tags
    Environment: 'Development'
    Scope: 'Internal'
  }
  properties: {
    hardwareProfile: {
      vmSize: devVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${devEnvironmentNamePrefix}${i}'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicDev[i].id
        }
      ]
    }
  }
}]

// Network Interfaces for Development VMs
resource nicDev 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, devVmCount): {
  name: '${devEnvironmentNamePrefix}Nic${i}'
  location: location
  tags: { //the appropriate tags
    Environment: 'Development'
    Scope: 'Internal'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

// Test VMs
resource testVms 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(0, testVmCount): {
  name: '${testEnvironmentNamePrefix}${i}'
  location: location
  tags: { //the appropriate tags
    Environment: 'Test'
    Scope: 'Internal'
  }
  properties: {
    hardwareProfile: {
      vmSize: testVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${testEnvironmentNamePrefix}${i}'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicTest[i].id
        }
      ]
    }
  }
}]

// Network Interfaces for Test VMs
resource nicTest 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, testVmCount): {
  name: '${testEnvironmentNamePrefix}Nic${i}'
  location: location
  tags: { //the appropriate tags
    Environment: 'Test'
    Scope: 'Internal'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]
