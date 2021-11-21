@maxLength(8)
param environment_prefix string

param environment_name string

@allowed([
  '3.2.3'
  '3.2.2'
  '3.2.1'
  '3.2.0'
])
param ghes_version string

@allowed([
  'Standard_D4ds_v4'
  'Standard_D8ds_v4'
  'Standard_D16ds_v4'
  'Standard_D32ds_v4'
])
param vm_size string

param location string = resourceGroup().location

@secure()
param admin_username string

@secure()
param admin_password string

// See https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines for more option
resource ghes_appliance 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: '${environment_prefix}-${environment_name}-ghes'
  location: location
  dependsOn: [
    ghes_appliance_vnet
  ]
  properties: {
    hardwareProfile: {
      vmSize: vm_size  
    }
    networkProfile: {
      networkApiVersion: '2020-11-01'
      networkInterfaceConfigurations: [
        {
          name: '${environment_prefix}-${environment_name}-ghes-nic'
          properties: {
            ipConfigurations: [
              {
                name: '${environment_prefix}-${environment_name}-ghes-nic-config'
                properties: {
                  subnet: {
                    id: ghes_appliance_vnet.properties.subnets[0].id
                  }
                  publicIPAddressConfiguration: {
                    name: '${environment_prefix}-${environment_name}-ghes-nic-publicip'
                    properties: {
                      dnsSettings: {
                        domainNameLabel: '${environment_prefix}-${environment_name}-ghes'
                      }
                      publicIPAddressVersion: 'IPv4'
                      publicIPAllocationMethod: 'Static'
                    }
                    sku: {
                      name: 'Basic'
                      tier: 'Regional'
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
    osProfile: {
      computerName: '${environment_prefix}-${environment_name}-ghes'
      adminUsername: admin_username
      adminPassword: admin_password
    }
    storageProfile: {
      imageReference: {
        offer: 'GitHub-Enterprise'
        publisher: 'GitHub'
        sku: 'GitHub-Enterprise'
        version: ghes_version
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          name: '${environment_prefix}-${environment_name}-ghes-datadisk'
          caching: 'ReadWrite'
          createOption: 'Empty'
          lun: 2
          diskSizeGB: 150
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ] 
    }
  }
}

resource ghes_appliance_nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: '${environment_prefix}-${environment_name}-ghes-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Git over SSH'
        properties: {
          access: 'Allow'
          protocol: '*'
          direction: 'Inbound'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          priority: 900
        }
      }
      {
        name: 'Web application access'
        properties: {
          access: 'Allow'
          protocol: '*'
          direction: 'Inbound'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          priority: 800
        }
      }
      {
        name: 'Instance SSH shell access'
        properties: {
          access: 'Allow'
          protocol: '*'
          direction: 'Inbound'
          destinationPortRange: '122'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          priority: 700
        }
      }
      {
        name: 'Web application and Git over HTTPS'
        properties: {
          access: 'Allow'
          protocol: '*'
          direction: 'Inbound'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          priority: 600
        }
      }
      {
        name: 'Secure web based management console'
        properties: {
          access: 'Allow'
          protocol: '*'
          direction: 'Inbound'
          destinationPortRange: '8443'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          priority: 500
        }
      }
    ]
  }
}

resource ghes_appliance_vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${environment_prefix}-${environment_name}-ghes-vnet'
  location: location
  dependsOn: [
    ghes_appliance_nsg
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${environment_prefix}-${environment_name}-ghes-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: ghes_appliance_nsg.id
          }
        }
      }
    ]
  }
}
