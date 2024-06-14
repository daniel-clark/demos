targetScope = 'resourceGroup'

param organisationCode string

param projectCode string

param locationShort string

param environment string

var storageAccountName = '${organisationCode}${projectCode}${locationShort}${environment}stor'
var storageContainerName = 'data-lake'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: resourceGroup().location

  sku: {
    name: 'Standard_LRS'
  }

  kind: 'StorageV2'

  properties: {
    isHnsEnabled: true
    accessTier: 'Hot'
  }
}


resource storageBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount

}

resource storageBlob 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: storageContainerName
  parent: storageBlobService

  properties: {
    publicAccess: 'None'
  }
}
