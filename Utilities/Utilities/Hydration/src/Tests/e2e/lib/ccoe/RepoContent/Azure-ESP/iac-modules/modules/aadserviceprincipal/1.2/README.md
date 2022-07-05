- [AAD Service Principal 1.2](#aad-service-principal-12)
  - [Component Design](#component-design)
  - [Release Notes](#release-notes)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
        - [`name`](#name)
        - [`applicationpermissions`](#applicationpermissions)
        - [`rotatePassword`](#rotatepassword)
        - [`outputVarName_ApplicationId`](#outputvarname_applicationid)
        - [`outputVarNameEncrypted_ServicePrincipalPassword`](#outputvarnameencrypted_serviceprincipalpassword)
      - [Outputs](#outputs)
        - [Application Id](#application-id)
      - [Secrets](#secrets)
        - [Service Principal Password](#service-principal-password)
      - [Example](#example)
        - [Configuration file](#configuration-file)
        - [Deployment YAML Pipeline](#deployment-yaml-pipeline)

# AAD Service Principal 1.2

## Component Design

An Azure [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals#service-principal-object) is a security identity used to access resources that are secured by an Azure AD tenant. Service Principals will represent many services which will need to be granted certain rights. Service Principals also represent Azure Applications in the local Azure AD tenant.

[An Azure AD Application object](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-application-objects) is frequently used as a conceptual term, referring to not only the application software, but also its Azure AD registration and role in authentication/authorization "conversations" at runtime.

The **App registrations blade** in the Azure portal is used to list and manage the application objects in your home tenant.

![App Registration blade in the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/media/app-objects-and-service-principals/app-registrations-blade.png)

A service principal is the local representation, or application instance, of a global application object in a single tenant or directory. A service principal is a concrete instance created from the application object and inherits certain properties from that application object. A service principal is created in each tenant where the application is used and references the globally unique app object. The service principal object defines what the app can actually do in the specific tenant, who can access the app, and what resources the app can access.

The **Enterprise applications blade** in the Azure portal is used to list and manage the service principals in a tenant. You can see the service principal's permissions, user consented permissions, which users have done that consent, sign in information, and more.

![Enterprise applications blade in the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/media/app-objects-and-service-principals/enterprise-apps-blade.png)

In this version of the component, the Azure Services Principal will be deployed with the following features:

+ The deployed AD Service Principal will be linked to an AD Application via AD Application Id
+ Random passwords can be configured as credentials for the Service Principal, and will be stored as a [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that can be reused by other jobs of the same stage encrypted via [ConvertFrom-SecureString](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.1#example-3--convert-a-secure-string-to-an-encrypted-standard-string-with-a-192-bit-key) cmdlet 
+ [API Permissions and consents](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent) can be configured


## Release Notes

**[2021.02.18] Version 1.2**

> + Service Principal updated with the following parameters:
>   - **rotatePassword**. Parameter to force the Service Principal to rotate the password. It will also remove all passwords except the 3 latest (the latest created + 2 newest)
>   - **outputVarName_ApplicationId**. Parameter to set Application Id as a [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that can be reused by other jobs in the same pipeline
>   - **outputVarNameEncrypted_ServicePrincipalPassword**. Parameter to set the Service Principal Password (encrypted via [ConvertFrom-SecureString](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.1#example-3--convert-a-secure-string-to-an-encrypted-standard-string-with-a-192-bit-key) cmdlet) as a [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that can be reused by other jobs of the same stage

## Operations

### Deployment

#### Parameters

##### `name`

- Type: `string`

Specifies the `DisplayName` to be set for the [Service Principal](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azadserviceprincipal?view=azps-5.5.0#parameters) and the [Application](https://docs.microsoft.com/en-us/powershell/module/az.resources/get-azadapplication?view=azps-5.5.0#parameters)

##### `applicationpermissions`

- Type: `object[]`

Array of [Application permissions and consents](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent) to be configured for the Service Principal.

Each Application Permission can be defined using the following schema:

```json
{
    "resourceAppId":"guid",
    "resourceAccess":[
        {
            "id":"guid",
            "type":"string"
        }
    ]
}
```

Where:
- `resourceAppId` is a `guid` with the resource identifier or application ID URI with the permission to be.
- `resourceAccess` is `object[]` where each item defines permission of the resource app Id to be granted. Each item in the array must contain:
  - `id` with the identifier of the permission to be granted
  - `type` with the type of the permission to be granted

The Microsoft identity platform implements the [OAuth 2.0](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-v2-protocols) authorization protocol. OAuth 2.0 is a method through which a third-party app can access web-hosted resources on behalf of a user. Any web-hosted resource that integrates with the Microsoft identity platform has a **resource identifier, or application ID URI**.

Any of these resources also can define a set of permissions that can be used to divide the functionality of that resource into smaller chunks. As an example, [Microsoft Graph](https://graph.microsoft.com/) has defined permissions to do the following tasks, among others:

- Read a user's calendar
- Write to a user's calendar
- Send mail as a user

The Microsoft identity platform supports two types of permissions: delegated permissions and application permissions.
- **Delegated permissions** are used by apps that have a signed-in user present. For these apps, either the user or an administrator consents to the permissions that the app requests. The app is delegated permission to act as the signed-in user when it makes calls to the target resource. Some delegated permissions can be consented to by nonadministrators. But some high-privileged permissions require administrator consent. To learn which administrator roles can consent to delegated permissions, see Administrator role permissions in Azure Active Directory (Azure AD).
- **Application permissions** are used by apps that run without a signed-in user present, for example, apps that run as background services or daemons. Only an administrator can consent to application permissions.

##### `rotatePassword`

- Type: `bool`
- Default value: `false`

Parameter to force the service principal to rotate the password when set to `true`. It will also remove all passwords except the 3 newest (the newly created password + 2 latest).

##### `outputVarName_ApplicationId`

- Type: `string`
- Default value: `{name}_ApplicationId`

Parameter to set the name of the [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that contains the application id of the service principal.

This multi-job output variable can be used by other jobs in the same YAML pipeline.

See [outputs](#outputs) for more details.

##### `outputVarNameEncrypted_ServicePrincipalPassword`

- Type: `string`
- Default value: `{name}_ServicePrincipalPassword`

Parameter to set the name of the [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that contains the rotated password of the Service Principal encrypted via [`ConvertFrom-SecureString` cmdlet](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.1#example-3--convert-a-secure-string-to-an-encrypted-standard-string-with-a-192-bit-key).

This multi-job output variable can be used by other jobs in the same YAML pipeline.

See [secrets](#secrets) for more details.

#### Outputs

##### Application Id

As an output of the service, a [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that contains the application id of the service principal will be created.

This variable will have the default name `[service-principal-name]_ApplicationId`. The name of this variable can be modified using the parameter [`outputVarName_ApplicationId`](#outputvarname_applicationid)

This multi-job output variable can be used by other jobs in the same YAML pipeline. In the example below, the variable is created in the stage `Test_03_Key_Rotation_with_ADO_Project`, job `deploytest03a` and task `deploy_module`.

In another job, the variable can be passed to a pipeline variable using the [stage dependencies syntax](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops#dependencies) `$[ dependencies.JOB_NAME.outputs['TASK_NAME.VARIABLE_NAME'] ]` for jobs in the same stage or `$[ stageDependencies.STAGE_NAME.JOB_NAME.outputs['TASK_NAME.VARIABLE_NAME'] ]` for jobs in different stages

```yaml
- stage: 'Test_03_Key_Rotation_with_ADO_Project'
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml
    parameters:
      serviceConnection: 'aad-automation'
      deploymentBlocks:
      - path: "$(modulePath)/parameters/test03.a-key_rotation_sp.json"
        jobName: deploytest03a
        displayName: 'test 03.a - deploy ${{ variables.moduleName }} ${{ variables.moduleVersion}}'
        taskName: deploy_module
  - template: /cicd/templates/pipeline.jobs.deploy.yml
    parameters:
      modulename: adoproject
      moduleversion: "1.0"
      minimumAzureCLIVersion: '2.18.0'
      minimumAzureCLIADOVerison: '0.18.0'
      dependsOn: deploytest03a
      deploymentBlocks:
      - path: "$(modulePath)/parameters/test03.b-key_rotation_adoproject.json"
        displayName: 'test 03.b - deploy adoproject 1.0'
        additionalVariables:
          pxs-cn-s-ccoe-sub_ApplicationId: $[ dependencies.deploytest03a.outputs['deploy_module.pxs-buildingblocks-deploytest03-sp_ApplicationId'] ]
          pxs-cn-s-ccoe-sub_ServicePrincipalPassword: $[ dependencies.deploytest03a.outputs['deploy_module.pxs-buildingblocks-deploytest03-sp_ServicePrincipalPassword'] ]
```

#### Secrets

##### Service Principal Password

As an output of the service, a [multi-job output variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable) that contains the rotated password of the Service Principal encrypted via [`ConvertFrom-SecureString` cmdlet](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.1#example-3--convert-a-secure-string-to-an-encrypted-standard-string-with-a-192-bit-key).

```PowerShell
$aadSpSecret = Set-Password @params | ConvertFrom-SecureString -Key (1..16)
```

To decrypt, the password must be converted to a [`Secure String` object](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring?view=net-5.0) using the [`ConvertTo-SecureString` cmdlet](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring?view=powershell-7.1#example-2--create-a-secure-string-from-an-encrypted-string-in-a-file)

```PowerShell
$AzureServicePrincipalSecret = ConvertTo-SecureString [System.Environment]::GetEnvironmentVariable($varNameEncrypted_ServicePrincipalPassword) -Key (1..16)
```

This variable will have the default name `[service-principal-name]_ServicePrincipalPassworD`. The name of this variable can be modified using the parameter [`outputVarNameEncrypted_ServicePrincipalPassword`](#outputvarnameencrypted_serviceprincipalpassword)

This multi-job output variable can be used by other jobs in the same YAML pipeline. In the example below, the variable is created in the stage `Test_03_Key_Rotation_with_ADO_Project`, job `deploytest03a` and task `deploy_module`.

In another job, the variable can be passed to a pipeline variable using the [stage dependencies syntax](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops#dependencies) `$[ dependencies.JOB_NAME.outputs['TASK_NAME.VARIABLE_NAME'] ]` for jobs in the same stage or `$[ stageDependencies.STAGE_NAME.JOB_NAME.outputs['TASK_NAME.VARIABLE_NAME'] ]` for jobs in different stages

```yaml
- stage: 'Test_03_Key_Rotation_with_ADO_Project'
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml
    parameters:
      serviceConnection: 'aad-automation'
      deploymentBlocks:
      - path: "$(modulePath)/parameters/test03.a-key_rotation_sp.json"
        jobName: deploytest03a
        displayName: 'test 03.a - deploy ${{ variables.moduleName }} ${{ variables.moduleVersion}}'
        taskName: deploy_module
  - template: /cicd/templates/pipeline.jobs.deploy.yml
    parameters:
      modulename: adoproject
      moduleversion: "1.0"
      minimumAzureCLIVersion: '2.18.0'
      minimumAzureCLIADOVerison: '0.18.0'
      dependsOn: deploytest03a
      deploymentBlocks:
      - path: "$(modulePath)/parameters/test03.b-key_rotation_adoproject.json"
        displayName: 'test 03.b - deploy adoproject 1.0'
        additionalVariables:
          pxs-cn-s-ccoe-sub_ApplicationId: $[ dependencies.deploytest03a.outputs['deploy_module.pxs-buildingblocks-deploytest03-sp_ApplicationId'] ]
          pxs-cn-s-ccoe-sub_ServicePrincipalPassword: $[ dependencies.deploytest03a.outputs['deploy_module.pxs-buildingblocks-deploytest03-sp_ServicePrincipalPassword'] ]
```

#### Example

##### Configuration file

The following JSON serves as an example for the parameters

```json
{
    "name": "pxs-buildingblocks-deploytest03-sp",
    "applicationpermissions":[
        {
            "resourceAppId":"00000003-0000-0000-c000-000000000000",
            "resourceAccess":[
                {
                    "id":"7ab1d382-f21e-4acd-a863-ba3e13f7da61",
                    "type":"Role"
                }
            ]
        },
        {
            "resourceAppId":"00000002-0000-0000-c000-000000000000",
            "resourceAccess":[
                {
                    "id":"5778995a-e1bf-45b8-affa-663a9f3f4d04",
                    "type":"Role"
                }
            ]
        }
    ],
    "rotatePassword": true,
    "outputVarName_ApplicationId": "pxs-buildingblocks-deploytest03-sp_ApplicationId",
    "outputVarNameEncrypted_ServicePrincipalPassword": "pxs-buildingblocks-deploytest03-sp_ServicePrincipalPassword"
}
```

##### Deployment YAML Pipeline

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the component:

```yaml
- stage: 'Deploy_ServicePrincipal'
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml
    parameters:
      serviceConnection: 'aad-automation'
      deploymentBlocks:
      - path: "$(modulePath)/parameters/service_principal.json"
        jobName: deploy_serviceprincipal
        displayName: 'Deploy Service Principal 1.2 with config file service_principal.json'
        taskName: deploy_module
```

