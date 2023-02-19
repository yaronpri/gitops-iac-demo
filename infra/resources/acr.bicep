@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Basic'

@description('Managed identity object id')
param manageidObjId string

resource acrResource 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
  }
}

var acrPullRole = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrPullRole, manageidObjId, acrResource.id)
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRole)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

var acrPushRole = '8311e382-0749-4cb8-b61a-304f252e45ec'
resource acrPushAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrPushRole, manageidObjId, acrResource.id)
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPushRole)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

output acrname string = acrResource.name
output acrresourceid string = acrResource.id
output acrloginserver string = acrResource.properties.loginServer
