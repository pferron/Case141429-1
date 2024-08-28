@description('The location to deploy resources to')
param location string = resourceGroup().location

@description('The target environment')
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

@description('Required. Azure AD app registration client id.')
param clientId string

var environmentMap = { dev: 'dev', test: 'tst', staging: 'stg', prod: 'prd' }

var resourceName = {
  applicationName: applicationName
  departmentCode: departmentCode
  environment: environmentMap[environment]
  sequenceNumber: sequenceNumber
}

var webappname = toLower('app-${resourceName.applicationName}-${resourceName.departmentCode}-${resourceName.environment}-${location}-${resourceName.sequenceNumber}')

resource app 'Microsoft.Web/sites@2021-03-01' existing = {
  name: webappname
}

resource azureAADAuthSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'authsettingsV2'
  kind: 'webapp'
  parent: app
  properties: {
      globalValidation: {
        redirectToProvider: 'azureactivedirectory'
        requireAuthentication: true
        unauthenticatedClientAction: 'RedirectToLoginPage'
      }
      httpSettings: {
        forwardProxy: {
          convention: 'NoProxy'
        }
        requireHttps: true
        routes: {
          apiPrefix: '/.auth'
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          login: {
            disableWWWAuthenticate: false
          }
          registration: {
            clientId: clientId
            clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
            openIdIssuer: 'https://sts.windows.net/${tenant().tenantId}/v2.0/'
          }
          validation: {
            jwtClaimChecks: {}
            allowedAudiences: [
                'api://${clientId}'
            ]
            defaultAuthorizationPolicy: {
                allowedPrincipals: {}
            }
          }
        }
      }      
      login: {
        cookieExpiration: {
          convention: 'FixedTime'
          timeToExpiration: '08:00:00'
        }
        nonce: {
          nonceExpirationInterval: '00:05:00'
          validateNonce: true
        }
        preserveUrlFragmentsForLogins: false
        routes: {}
        tokenStore: {
          azureBlobStorage: {}
          enabled: true
          fileSystem: {}
          tokenRefreshExtensionHours: 72
        }
      }
      platform: {
        enabled: true
        runtimeVersion: '~1'
      }
  }
}
