@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('AKS resource name')
param clusterName string

@description('AKS dns prefix')
param clusterDNSPrefix string

@description('Admin user name for AKS node')
param adminusername string

@description('AKS node ssh public key')
@secure()
param sshPubKey string

@description('AKS authorized ip range')
param iprange string = ''

@description('LogAnalytic workspace id')
param logAnalyticId string = ''

@description('Managed identity name')
param managedIdentityName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

resource controlplanemanagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${managedIdentityName}-cp'
  location: location
}

//f1a07417-d97a-45cb-824c-7a7467783830 - Managed Identity Operator
var managedIDentityOperatorRole = 'f1a07417-d97a-45cb-824c-7a7467783830'
resource  managedIDentityOperatorRAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIDentityOperatorRole, managedIdentityName, controlplanemanagedIdentity.name)
  scope: managedIdentity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', managedIDentityOperatorRole)
    principalId: controlplanemanagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource akscluster 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  name: clusterName
  location: location  
  identity: {
    type:'UserAssigned' 
    userAssignedIdentities: {
      '${controlplanemanagedIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: clusterDNSPrefix
    enableRBAC: true
    apiServerAccessProfile: !empty(iprange) ? {
      authorizedIPRanges: [iprange]
    } : null
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 30
        count: 1
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }      
    ]
    linuxProfile: {
      adminUsername: adminusername
      ssh: {
        publicKeys: [
          {
            keyData: sshPubKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    identityProfile: {
      kubeletidentity:{
        resourceId: managedIdentity.id
        clientId: managedIdentity.properties.clientId
        objectId: managedIdentity.properties.principalId
      }
    }
    addonProfiles: !empty(logAnalyticId) ? {
      omsagent:{
        enabled: true 
        config: {
          logAnalyticsWorkspaceResourceID : logAnalyticId
        }       
      }
    } : null
  }
}

output aksclusterfqdn string = akscluster.properties.fqdn
output aksresourceid string = akscluster.id
output aksresourcename string = akscluster.name
