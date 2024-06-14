targetScope = 'resourceGroup'

param organisationCode string

param projectCode string

param locationShort string

param environment string

var sqlServerName = '${organisationCode}-${projectCode}-${locationShort}-${environment}-sqlserver'
var sqlDbName = '${projectCode}db'


resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location

  properties: {
    administratorLogin: 'sqladmin'

  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: sqlDbName
  location: 'west europe'

  parent: sqlServer

  sku: {
    name: 'Standard'
    tier: 'Standard'
    size: '10'
  }

  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    sampleName: 'WideWorldImportersFull'
  }
}

resource thing 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-08-01-preview' = {
  name: 'default'
  parent: sqlServer

  properties: {
    storageContainerPath: 'sqlvulnerabilityassessments'
    storageAccountAccessKey: 'todo'
    recurringScans: {
      
      isEnabled: true
      emails: [
        'example@example.com'
      ]
    }
  }
}
