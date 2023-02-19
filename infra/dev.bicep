targetScope = 'subscription'

param location string = deployment().location

@minLength(1)
@maxLength(16)
@description('Prefix for all deployed resources')
param name string

@description('SSH Public Key')
@secure()
param sshpublickey string

@description('AKS authorized ip range')
param authiprange string = ''

var resourcegroup = '${name}-rg' 
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourcegroup
  location: location
}

module identity 'resources/managedid.bicep' = {
  name: '${rg.name}-identity'
  scope: rg
  params: {
    location: location
    managedIdentityName: toLower(name)
  }
}

var acrName = 'acr${uniqueString(rg.id)}' 
module acr 'resources/acr.bicep' = {
  name: '${rg.name}-acr'
  scope: rg
  params: {
    acrName: acrName
    location: rg.location
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}

var aksclustername = '${name}-aks'
var adminusername = '${name}admin'
module aks 'resources/aks.bicep' = {
  name: '${rg.name}-aks'
  scope: rg
  params: {
    clusterName: aksclustername
    adminusername: adminusername
    location: location
    clusterDNSPrefix: aksclustername       
    sshPubKey: sshpublickey
    managedIdentityName: identity.outputs.managedIdentityName  
    iprange: authiprange
  }
}

output resourcegroupname string = rg.name
output acrloginserver string = acr.outputs.acrloginserver
output acrresourceid string = acr.outputs.acrresourceid
output acrresoucename string = acr.outputs.acrname
output aksclusterfqdn string = aks.outputs.aksclusterfqdn
output aksresourceid string = aks.outputs.aksresourceid
output aksresourcename string = aks.outputs.aksresourcename
output managedidentityprincipalid string = identity.outputs.managedIdentityPrincipalId
output managedidentityclientid string = identity.outputs.managedIdentityClientId
output managedidentityresourceid string = identity.outputs.managedIdentityResourceId
output managedidentityname string = identity.outputs.managedIdentityName

