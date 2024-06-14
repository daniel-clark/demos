targetScope = 'subscription'

param organisationCode string

param projectCode string

param location string

param locationShort string

param environment string

var resourceGroupName = '${organisationCode}-${projectCode}-${locationShort}-${environment}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}
