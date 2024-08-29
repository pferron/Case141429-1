@description('Optional. The location to deploy resources to. Default: resourceGroup().location')
param location string = resourceGroup().location

@description('Optional. The target environment. Default: dev')
@allowed([
  'dev'
  'test'
  'staging'
  'prod'
])
param environment string = 'dev'

@minLength(1)
@maxLength(2) // controls resource name length violations
@description('Optional. The sequence number to use in the resource naming. Default: 01')
param sequenceNumber string = '01'

@minLength(1)
@maxLength(8) // controls resource name length violations
@description('Required. The application name (e.g. arc, polaris, etc.) to use in the resource naming.')
param applicationName string

@minLength(1)
@maxLength(8) // controls resource name length violations
@description('Required. The department code (e.g. dah, ehps, cap, etc.) to use in the resource naming.')
param departmentCode string

@description('Required. The id of the service principal')
param servicePrincipalId string

@description('Required. The service principal key')
@secure()
param servicePrincipalKey string

@description('The id of the enterprise application object')
param spnEnterpriseAppObjectId string

@description('Required. The name of the app service plan resource group')
param appServicePlanResourceGroup string

@description('Required. The name of the app service plan')
param appServicePlanName string

@description('Subnet Address Prefix of the APIM instance')
param apimSubnetAddressPrefix string

var environmentMap = { dev: 'dev', test: 'tst', staging: 'stg', prod: 'prd' }

var environmentMapForKeyVault = { dev: 'dv', test: 'ts', staging: 'st', prod: 'pd' }

var regionMap = {westus2: 'w2', southcentralus: 'sc'}

var deploySlots = [
  'staging'
]

var appAccess = [
  'get'
  'list'
]

var spnKeyAccess = [
  'backup'
  'create'
  'decrypt'
  'delete'
  'encrypt'
  'get'
  'getrotationpolicy'
  'import'
  'list'
  'recover'
  'restore'
  'rotate'
  'setrotationpolicy'
  'sign'
  'unwrapKey'
  'update'
  'verify'
  'wrapKey'
 ]

 var spnSecretAccess = [
  'backup'
  'delete'
  'get'
  'list'
  'recover'
  'restore'
  'set'
 ]

var spnCertAccess = [ 
  'backup'
  'create'
  'delete'
  'deleteissuers'
  'get'
  'getissuers'
  'import'
  'list'
  'listissuers'
  'managecontacts'
  'manageissuers'
  'recover'
  'restore'
  'setissuers'
  'update'
 ]

// Session affinity setting
var clientAffinityEnabled = false

var apiResourceName = {
  applicationName                     : '${applicationName}'
  departmentCode                      : departmentCode
  environment                         : environmentMap[environment]
  sequenceNumber                      : sequenceNumber
}

var keyVaultName = toLower('kv${apiResourceName.applicationName}${apiResourceName.departmentCode}${environmentMapForKeyVault[environment]}${regionMap[location]}${apiResourceName.sequenceNumber}')

module keyVault 'br:pbcbicepprod.azurecr.io/keyvault:1.1.6-preview' = {
  name  : '${uniqueString(deployment().name, location)}-keyVault'
  params:{
    location                          : location
    keyVaultName                      : keyVaultName
    servicePrincipalId                : servicePrincipalId
    servicePrincipalKey               : servicePrincipalKey
    useRbacAuthorization              : false
  }
}

module allResourceName 'br:pbcbicepprod.azurecr.io/resourcename:1.0.2' = {
  name  : 'resourceName'
  params: {
    applicationName                   : apiResourceName.applicationName
    departmentCode                    : apiResourceName.departmentCode
    location                          : location
    sequenceNumber                    : apiResourceName.sequenceNumber
    environment                       : apiResourceName.environment
  }
}

module apiWebApp 'br:pbcbicepprod.azurecr.io/webapp:1.0.7' = {
  name: '${uniqueString(deployment().name, location)}-webApp-api'
  params:{
    location                          : location
    resourceName                      : apiResourceName
    appServicePlanName                : appServicePlanName
    appServicePlanResourceGroupName   : appServicePlanResourceGroup
    clientAffinityEnabled             : clientAffinityEnabled
    useDefaultLogAnalyticsWorkspace   : true
    appSettingsKeyValuePairs          : {
      AppConfigUri    : 'https://${allResourceName.outputs.appConfig}.azconfig.io'
    }
    deploySlots                       : deploySlots
    netFrameworkVersion               : 'v8.0'
    currentApplicationStack           : 'dotnet'
    alwaysOn                          : false
    alwaysOnDeploymentSlots           : false

    siteConfig                        : {
      ipSecurityRestrictions: [
        {
          ipAddress : apimSubnetAddressPrefix
          action    : 'Allow'
          priority  : '100'
          name      : 'Allow-Only-APIM'
        }
      ]
      ipSecurityRestrictionsDefaultAction: 'Deny'
    }
  }
  dependsOn: [
    keyVault
    allResourceName
  ]
}

module apiWebAppSlotUpdates './deploy-api-infra-slotupdates.bicep' = {
  name: '${uniqueString(deployment().name, location)}-apiWebAppSlotUpdates'
  params: {
    appName                           : apiWebApp.outputs.webAppName
    appServicePlanName                : appServicePlanName
    appServicePlanResourceGroupName   : appServicePlanResourceGroup
    location                          : location
    deploySlots                       : deploySlots
    siteConfig                        : {
      ipSecurityRestrictions: [
        {
          ipAddress : apimSubnetAddressPrefix
          action    : 'Allow'
          priority  : '100'
          name      : 'Allow-Only-APIM'
        }
      ]
      
      ipSecurityRestrictionsDefaultAction: 'Deny'
    }
  }
  dependsOn: [
    apiWebApp
  ]
}

module apiKeyVaultAccessPolicy 'br:pbcbicepprod.azurecr.io/keyvaultaccesspolicy:1.0.4' = {
  name: '${uniqueString(deployment().name, location)}-keyVaultAccessPolicy'
  params: {
    keyVaultName: keyVaultName
    accessPolicies: [
      { 
        objectId: spnEnterpriseAppObjectId
        permissions: { 
          certificates: spnCertAccess
          keys: spnKeyAccess
          secrets: spnSecretAccess
        }
        tenantId: subscription().tenantId 
      }
      { 
        objectId: apiWebApp.outputs.systemAssignedPrincipalId
        permissions: { 
          certificates: []
          keys: []
          secrets: appAccess
        }
        tenantId: subscription().tenantId 
      }
    ]
  }
  dependsOn: [
    keyVault
    allResourceName
    apiWebApp
  ]
}

module apiKeyVaultAccessPolicySlots 'br:pbcbicepprod.azurecr.io/keyvaultaccesspolicy:1.0.4' = {
  name: '${uniqueString(deployment().name, location)}-keyVaultAccessPolicySlots'
  params: {
    keyVaultName: keyVaultName
    accessPolicies: [for (deployslot, index) in deploySlots: {
      objectId: apiWebApp.outputs.deploySlotsInfo[index].systemAssignedPrincipalId
      permissions: { 
        certificates: []
        keys: []
        secrets: appAccess
      } 
      tenantId: subscription().tenantId 
    }]
  }
  dependsOn: [
    keyVault
    allResourceName
    apiWebApp
    apiKeyVaultAccessPolicy
  ]
}

output apiWebAppName    string = apiWebApp.outputs.webAppName
