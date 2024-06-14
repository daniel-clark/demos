targetScope = 'resourceGroup'

param organisationCode string

param projectCode string

param locationShort string

param environment string

param administratorGroup object = {
  objectId: 'ef1e50d2-63b6-4e90-9c34-06806e325b26'
  name: 'Geeks'
}

var sqlServerName = '${organisationCode}-${projectCode}-${locationShort}-${environment}-sqlserver'

var dbNames = [
  'demo1'
  'demo2'
  'demo3'
]


resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location
  properties: {

    administrators: {
      login: 'sqladmin'
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      tenantId: tenant().tenantId
      principalType: 'Group'
      sid: administratorGroup.objectId
    }
    minimalTlsVersion: '1.3'
  }
}

resource sqlDbs 'Microsoft.Sql/servers/databases@2023-08-01-preview' = [for dbName in dbNames: {
  name: dbName
  location: resourceGroup().location
  parent: sqlServer
  
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'

  }

  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}]


resource sqlFirewallRules 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: 'AllowAllAzure'
  parent: sqlServer

  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }

}
