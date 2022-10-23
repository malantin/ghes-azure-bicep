@maxLength(8)
param environment_prefix string

param environment_name string

@allowed([
  '3.6.2'
  '3.3.5'
  '3.3.2'
  '3.2.7'
  '3.2.10'
  '3.1.18'
  '3.1.15'
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
@description('Password or SSH public key is required. SSH is recommended.')
param admin_ssh_public_key string

@secure()
@description('If you have set an SSH public key, a password is not required.')
param admin_password string

@description('How many replicas do you want to create, including your primary?')
@allowed([
  1
  2
  3
])
param number_of_replicas int

// See https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines for more option
resource ghes_appliance 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(1, number_of_replicas):{
  name: '${environment_prefix}-${environment_name}-ghes-${i}'
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
          name: '${environment_prefix}-${environment_name}-ghes-${i}-nic'
          properties: {
            ipConfigurations: [
              {
                name: '${environment_prefix}-${environment_name}-ghes-${i}-nic-config'
                properties: {
                  subnet: {
                    id: ghes_appliance_vnet.properties.subnets[0].id
                  }
                  publicIPAddressConfiguration: {
                    name: '${environment_prefix}-${environment_name}-ghes-${i}-nic-publicip'
                    properties: {
                      dnsSettings: {
                        domainNameLabel: '${environment_prefix}-${environment_name}-ghes-${i}'
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
      computerName: '${environment_prefix}-${environment_name}-ghes-${i}'
      adminUsername: admin_username
      adminPassword: (!empty(admin_password)? admin_password : null)
      linuxConfiguration: {
        disablePasswordAuthentication: (empty(admin_ssh_public_key) ? false : true)
        ssh: (!empty(admin_ssh_public_key) ? {
          publicKeys: [
            {
              keyData: admin_ssh_public_key
              path: '/home/${admin_username}/.ssh/authorized_keys'
            }
          ]
        }: null)
      }
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
          name: '${environment_prefix}-${environment_name}-ghes-${i}-datadisk'
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
}]

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
