targetScope = 'resourceGroup'

param organisationCode string

param projectCode string

param locationShort string

param environment string

@secure()
param adminPassword string


var resourceGroupName = '${organisationCode}-${projectCode}-${locationShort}-${environment}'
var virtualMachineName = '${organisationCode}-${projectCode}-${locationShort}-vm' // Usually this would be '${resourceGroupName}-vm' but windows vms are limited to 15 characters
var vmDiskName = '${virtualMachineName}-disk'

var vNetName = '${resourceGroupName}-vnet'
var subNetName = 'default'
var publicIpName = '${virtualMachineName}-ip'
var networkInterfaceName = '${virtualMachineName}-nic'
var networkSecurityGroupName = '${resourceGroupName}-nsg'
var vmShutdownName = 'shutdown-computevm-${virtualMachineName}' // must be named like this

var adminUsername = '${projectCode}${environment}admin'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: virtualMachineName
  location: resourceGroup().location

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }

    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        name: vmDiskName
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }

      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-hotpatch'
        version: 'latest'
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: virtualMachineNetworkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }

    additionalCapabilities: {
      hibernationEnabled: false
    }

    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true

        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'Always'
          }
        
        }
      }
    }

    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
  zones: [
    '1'
  ]
}

resource vNet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vNetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subNetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource virtualMachineNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location

  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 300
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 320
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'RDP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 330
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource virtualMachineIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: resourceGroup().location

  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
  }

  zones: [
    '1'
  ]
}


resource virtualMachineNetworkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: networkInterfaceName
  location: resourceGroup().location

  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vNet.properties.subnets[0].id   // Note: taking the first subnet rather than referencing by name
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: virtualMachineIp.id
            properties: {
               deleteOption: 'Delete'
            }
          }
        }
      }
    ]

    networkSecurityGroup: {
      id: virtualMachineNetworkSecurityGroup.id
    }
  }

}


resource vmAutoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: vmShutdownName
  location: resourceGroup().location

  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'

    dailyRecurrence: {
      time: '20:00'
    }

    timeZoneId: 'UTC'

    targetResourceId: virtualMachine.id

    notificationSettings: {
      status: 'Disabled'
    }
  }
}
