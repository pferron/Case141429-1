/////// Parameters ///////
@description('''
Required. An object containing properties required to construct compliant resource names. 
The sum of the length of these parameters shouldn't exceed the maximum length allowed by the 
resource(s) that are deployed. Refer to the Azure documentation for details on length restrictions.

Custom object:
- applicationName: Required. The name of the application.
- departmentCode: Required. The department code.
- environment: Required. The environment name.
- sequenceNumber: Required. The sequence number.
- regionName: Optional. The name of the region to use in the resource name. If not specified, the default 
naming convention for the resource's region name is used.
''')
param resourceName object

@description('Optional. The location to deploy resources to. Default: resourceGroup().location.')
param location string = resourceGroup().location

@description('Required. The name the app service plan to use.')
param appServicePlanName string

@description('Required. The name of the resource group name that the app service plan belongs to.')
param appServicePlanResourceGroupName string

@description('Optional. Array of string values for Deployment Slots.')
param deploySlots array = []

@description('''
Optional. The Event Hub object where the diagnostic settings should log to. If not specified, the default shared event hub is used.

Custom object:
- subscriptionId: Required. The Id of the subscription.
- resourceGroupName: Required. The name of the Resource Group.
- namespace: Required. The namespace.
- name: Required. The name of the Event Hub.
- authorizationRule: Required. The Authorization Rule.
''')
param eventHub object = {}

@description('''
Optional. The Log Analytics Workspace diagnostic settings should log to. If not specified and useDefaultLogAnalyticsWorkspace is false, diagnostic
logging settings are not sent to a log anylitics workspace.

Custom object:
- subscriptionId: Required. The Id of the Subscription.
- resourceGroupName: Required. The name of the Resource Group.
- workspaceName: Required. The name of the Workspace.
- id: Required. The Resource Id of the Log Analytics Workspace.
''')
param logAnalyticsWorkspace object = {}

@description('''
Optional. The Log Analytics Workspace that Application Insights should log to. 
If not specified the appropriate existing workspace will be used based on the environment you are deploying to.

Object properties:
- id: Required. The Resource Id of the Log Analytics Workspace.
''')
param applicationInsightsLogAnalyticsWorkspace object = {}

@description('''
Optional. Indicates if the default shared log analytics workspace should be used to send diagnostic logs to. Overrides the 
logAnalyticsWorkspace parameter when set to true. If false and logAnalyticsWorkspace is not specified, diagnostic
logging settings are not sent to a log anylitics workspace.
''')
param useDefaultLogAnalyticsWorkspace bool = false

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = true

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('''Optional. Declared AppSettings key value pairs.

Example object:
{
  ENABLE_ORYX_BUILD: 'true'
  linuxFxVersion: 'python|3.10'
  SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
}

See https://learn.microsoft.com/en-us/azure/app-service/reference-app-settings for more information.
''')
param appSettingsKeyValuePairs object = {}

@description('Optional. The site config object.')
param siteConfig object = {}

@description('''
Optional. Existing App Insight Object:
- subscriptionId: Required. The Id of the Subscription.
- resourceGroupName: Required. The name of the Resource Group.
- name: Required. The name of the App Insights resource.
''')
param appInsight object = {}

@description('Optional. The connection string to use. Must be used with connectionStringDatabaseType.')
param connectionStringValue string = ''

@description('Optional. The type of database connection string. Must be used with connectionStringValue.')
@allowed([
  'n/a'
  'ApiHub'
  'Custom'
  'DocDb'
  'EventHub'
  'MySql'
  'NotificationHub'
  'PostgreSQL'
  'RedisCache'
  'SQLAzure'
  'SQLServer'
  'ServiceBus'
])
param connectionStringDatabaseType string = 'n/a'

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Optional. The custom hostname that you wish to add.')
param customHostnames array = []

@description('Optional. Existing Key Vault resource Id for the SSL certificate, leave this blank if not enabling SSL.')
param existingKeyVaultId string = ''

@description('Optional. Key Vault Secret that contains a PFX certificate, leave this blank if not enabling SSL.')
param existingKeyVaultCertificateName string = ''

@description('Optional. Specify the type of lock.')
@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
param lock string = ''

@description('[Deprecated]. This parameter is not used and will be removed in a future release.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 30

@description('Optional. Tags to apply to the resource. Defaults to the resource group tags.')
param tags object = resourceGroup().tags

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('''
Optional. The .NET version. Default: \'\'.

The Portal displayed values and the actual underlying API values differ for this setting, as follows:

ASP.NET V3.5: v2.0.
ASP.NET V4.8: v4.0.
.NET 6 (LTS): v6.0.
.NET 7 (STS): v7.0.
.NET 8 (LTS) (preview): v8.0.
''')
@allowed([
  'v2.0'
  'v3.0'
  'v4.0'
  'v5.0'
  'v6.0'
  'v7.0'
  'v8.0'
  ''
])
param netFrameworkVersion string = ''

@description('Optional. Version of Node.js.')
param nodeVersion string = ''

@description('Optional. Version of PHP.')
param phpVersion string = ''

@description('Optional. Version of Python.')
param pythonVersion string = ''

@description('Optional. Version of Java.')
param javaVersion string = ''

@description('Optional. The Application Stack for the Web App. Default: dotnetcore.')
@allowed([
  'dotnet'
  'dotnetcore'
  'node'
  'python'
  'php'
  'java'
])
param currentApplicationStack string = 'dotnetcore'

@description('''Optional. Always on is a feature that keeps your app loaded all the time, which can help improve the performance of the app and reduce cold start times.
if resourceName.environment is set to 'prod', alwaysOn is true, else false.
''')
param alwaysOn bool = toLower(resourceName.environment) == 'prod' ? true : false

@description('''Optional. Always on is a feature that keeps your app loaded all the time, which can help improve the performance of the app and reduce cold start times.
if resourceName.environment is set to 'prod', alwaysOn is true, else false.
''')
param alwaysOnDeploymentSlots bool = toLower(resourceName.environment) == 'prod' ? true : false

@description('''
Optional. Relative path of the health check probe.
 
Note: If set, will cause instance replacement when infrastructure is deployed before the app is deployed.
Please see https://learn.microsoft.com/en-us/azure/app-service/monitor-instances-health-check for more information.
''')
param healthCheckPath string = ''

/////// Variables ///////
@description('Required. Type of site to deploy.')
var kind = 'webapp'

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
var httpsOnly = true

@description('Required. TResource type of WebApp.')
var resourceType = 'app'

var regionName = contains(resourceName, 'regionName') ? resourceName.regionName : location

@description('Required. Name of Web App.')
var webAppName = toLower('${resourceType}-${resourceName.applicationName}-${resourceName.departmentCode}-${resourceName.environment}-${regionName}-${resourceName.sequenceNumber}')

var publicNetworkAccess = 'Enabled'

var clientCertEnabled = true

var clientCertMode = 'OptionalInteractiveUser'

@description('Required. http 2.0 enabled to ensure ASB and CIS complaince.')
var http20Enabled = true

@description('Required, minimum TLS Version Enabled to ensure ASB and CIS complaince.')
var minTlsVersion = '1.2'

@description('Required client Cert Enabled to ensure ASB and CIS complaince.')
var ftpsState = 'FtpsOnly'

var buildPrefix = '${uniqueString(deployment().name, location)}_webApp'

var appServicePlanId = resourceId(
  subscription().subscriptionId,
  appServicePlanResourceGroupName,
  'Microsoft.Web/serverFarms',
  appServicePlanName
)

@description('Optional. The name of logs that will be streamed.')
var diagnosticLogCategoriesToEnable = [
  'AppServiceConsoleLogs'
  'AppServiceHTTPLogs'
  'AppServiceAuditLogs'
  'AppServiceFileAuditLogs'
  'AppServiceAppLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Optional. The name of metrics that will be streamed.')
var diagnosticMetricsToEnable = ['AllMetrics']

var diagnosticsLogs = [
  for category in diagnosticLogCategoriesToEnable: {
    category: category
    enabled: true
    // retentionPolicy: {
    //   enabled: true
    //   days: diagnosticLogsRetentionInDays
    // }
  }
]

var diagnosticsMetrics = [
  for metric in diagnosticMetricsToEnable: {
    category: metric
    timeGrain: null
    enabled: true
    // retentionPolicy: {
    //   enabled: true
    //   days: diagnosticLogsRetentionInDays
    // }
  }
]

var identityType = systemAssignedIdentity
  ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned')
  : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None'
  ? {
      type: identityType
      userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
    }
  : null

var logAnalyticsWorkspaceObj = useDefaultLogAnalyticsWorkspace
  ? sharedResources.outputs.sharedLogAnalyticsWorkspaceObj
  : (!empty(logAnalyticsWorkspace) ? logAnalyticsWorkspace : {})
var appInsightsLAW = !empty(applicationInsightsLogAnalyticsWorkspace)
  ? applicationInsightsLogAnalyticsWorkspace
  : sharedResources.outputs.sharedLogAnalyticsWorkspaceObj

var eventHubObj = !empty(eventHub)
  ? eventHub
  : first(filter(sharedResources.outputs.sharedSplunkEventHubObjs, x => x.resourceType == 'webApp'))

module sharedResources './../ecp/shared-resources/deploy.bicep' = {
  name: '${buildPrefix}_sharedResources'
  params: {
    location: location
  }
}

resource existingAppInsight 'Microsoft.Insights/components@2020-02-02' existing =
  if (!empty(appInsight)) {
    name: appInsight.name
    scope: resourceGroup(appInsight.subscriptionId, appInsight.resourceGroupName)
  }

resource appi 'Microsoft.Insights/components@2020-02-02' =
  if (empty(appInsight)) {
    name: '${webAppName}-appInsight'
    location: location
    kind: 'web'
    properties: {
      Application_Type: 'web'
      IngestionMode: 'LogAnalytics'
      WorkspaceResourceId: appInsightsLAW.id
    }
    tags: tags
  }

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appServicePlanName
  scope: resourceGroup(appServicePlanResourceGroupName)
}

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: kind
  tags: tags
  identity: identity
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: clientAffinityEnabled
    clientCertEnabled: clientCertEnabled
    clientCertMode: clientCertEnabled ? clientCertMode : null
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: appServicePlan.properties.hostingEnvironmentProfile
    publicNetworkAccess: publicNetworkAccess
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: (empty(appInsight))
            ? appi.properties.InstrumentationKey
            : existingAppInsight.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: (empty(appInsight)) ? appi.properties.ConnectionString : existingAppInsight.properties.ConnectionString
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: currentApplicationStack
        }
      ]
      alwaysOn: alwaysOn
      nodeVersion: empty(nodeVersion) ? null : nodeVersion
      javaVersion: empty(javaVersion) ? null : javaVersion
      pythonVersion: empty(pythonVersion) ? null : pythonVersion
      phpVersion: empty(phpVersion) ? null : phpVersion
      netFrameworkVersion: empty(netFrameworkVersion) ? null : netFrameworkVersion
      http20Enabled: http20Enabled
      minTlsVersion: minTlsVersion
      ftpsState: ftpsState
      publicNetworkAccess: publicNetworkAccess
      healthCheckPath: empty(healthCheckPath) ? null : healthCheckPath
    }
  }
}

resource appSlots 'Microsoft.Web/sites/slots@2022-09-01' = [
  for (deployslot, index) in deploySlots: {
    name: '${deployslot}-${index}'
    location: location
    parent: app
    tags: tags
    identity: identity
    properties: {
      serverFarmId: appServicePlan.id
      clientAffinityEnabled: clientAffinityEnabled
      clientCertEnabled: clientCertEnabled
      clientCertMode: clientCertEnabled ? clientCertMode : null
      httpsOnly: httpsOnly
      publicNetworkAccess: publicNetworkAccess
      siteConfig: {
        appSettings: [
          {
            name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
            value: (empty(appInsight))
              ? appi.properties.InstrumentationKey
              : existingAppInsight.properties.InstrumentationKey
          }
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: (empty(appInsight))
              ? appi.properties.ConnectionString
              : existingAppInsight.properties.ConnectionString
          }
        ]
        metadata: [
          {
            name: 'CURRENT_STACK'
            value: currentApplicationStack
          }
        ]
        alwaysOn: alwaysOnDeploymentSlots 
        nodeVersion: empty(nodeVersion) ? null : nodeVersion
        javaVersion: empty(javaVersion) ? null : javaVersion
        pythonVersion: empty(pythonVersion) ? null : pythonVersion
        phpVersion: empty(phpVersion) ? null : phpVersion
        netFrameworkVersion: empty(netFrameworkVersion) ? null : netFrameworkVersion
        http20Enabled: http20Enabled
        minTlsVersion: minTlsVersion
        ftpsState: ftpsState
        publicNetworkAccess: publicNetworkAccess
        healthCheckPath: empty(healthCheckPath) ? null : healthCheckPath
      }
    }
  }
]

module app_appsettings './../appservice/config-appsettings/appsetting.bicep' =
  if (!empty(appSettingsKeyValuePairs)) {
    name: '${buildPrefix}_AppSettings'
    params: {
      currentAppSettings: list('${app.id}/config/appsettings', '2022-09-01').properties
      appSettingsKeyValuePairs: appSettingsKeyValuePairs
      appName: webAppName
    }
  }

module certificateBindings './../appservice/certificate/deploy.bicep' = {
  name: '${buildPrefix}_SSL'
  params: {
    appServicePlanResourceId: appServicePlanId
    customHostnames: customHostnames
    location: location
    existingKeyVaultId: existingKeyVaultId
    existingKeyVaultCertificateName: existingKeyVaultCertificateName
    appName: app.name
  }
}

resource app_connectionStrings 'Microsoft.Web/sites/config@2022-09-01' =
  if (!empty(connectionStringValue) && (connectionStringDatabaseType != 'n/a')) {
    name: 'connectionstrings'
    parent: app
    properties: {
      connectionName: {
        #disable-next-line BCP036 // invalid property value 'n/a' is excluded from use thru if condition
        type: connectionStringDatabaseType
        value: connectionStringValue
      }
    }
  }

resource app_lock 'Microsoft.Authorization/locks@2017-04-01' =
  if (!empty(lock)) {
    name: '${app.name}-${lock}-lock'
    properties: {
      level: any(lock)
      notes: lock == 'CanNotDelete'
        ? 'Cannot delete resource or child resources.'
        : 'Cannot modify the resource or child resources.'
    }
    scope: app
  }

module app_siteconfig './../appservice/config-site/deploy.bicep' = {
  name: '${buildPrefix}_siteConfig'
  params: {
    appName: app.name
    siteConfig: siteConfig
  }
}

resource eventhubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubObj.namespace
  scope: resourceGroup(eventHubObj.subscriptionId, eventHubObj.resourceGroupName)
}

resource eventHub_AuthorizationPolicy 'Microsoft.EventHub/namespaces/AuthorizationRules@2022-01-01-preview' existing = {
  parent: eventhubNamespace
  name: eventHubObj.authorizationRule
}

resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${app.name}-diag'
  properties: {
    workspaceId: !empty(logAnalyticsWorkspaceObj) ? logAnalyticsWorkspaceObj.id : null
    eventHubAuthorizationRuleId: eventHub_AuthorizationPolicy.id
    eventHubName: eventHubObj.name
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: app
}

module app_roleAssignments './../appservice/.bicep/nested-roleAssignments.bicep' = [
  for (roleAssignment, index) in roleAssignments: {
    name: '${buildPrefix}-Site-Rbac-${index}'
    params: {
      description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
      principalIds: roleAssignment.principalIds
      principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
      roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
      condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
      delegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId')
        ? roleAssignment.delegatedManagedIdentityResourceId
        : ''
      resourceId: app.id
    }
  }
]

@description('The name of the site.')
output webAppName string = app.name

@description('The resource ID of the site.')
output webAppId string = app.id

@description('The resource group the site was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(app.identity, 'principalId')
  ? app.identity.principalId
  : ''

@description('''
Collection of deployment slot outputs.

Custom object:
- name: The deploy slot name created
- systemAssignedPrincipalId: The principal ID of the system assigned identity.
''')
output deploySlotsInfo array = [
  for (deployslot, index) in deploySlots: {
    name: appSlots[index].name
    systemAssignedPrincipalId: systemAssignedIdentity && contains(appSlots[index].identity, 'principalId')
      ? appSlots[index].identity.principalId
      : ''
  }
]

@description('The location the resource was deployed into.')
output location string = app.location
