# Role Definitions

This module deploys custom RBAC Role Definitions on Management Group scope.

## Resource types

|Resource Type|ApiVersion|
|:--|:--|
|`Microsoft.Authorization/roleDefinitions`|2018-01-01-preview|

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `roleName` | string | | | Required. Name of the custom RBAC role to be created.
| `roleDescription` | string | "" | | Optional. Description of the custom RBAC role to be created.
| `actions` | array | [] | | Optional. List of allowed actions.
| `notActions` | array | [] | | Optional. List of denied actions.
| `dataActions` | array | [] | | Optional. List of allowed data actions.
| `notDataActions` | array | [] | | Optional. List of denied data actions.
| `managementGroupId` | string | | | Required. Id of the Management Group where the role should be available.

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `definitionObject` | object | The role definition object. |
| `definitionExtendedID` | string | The full role definition object ID. |

## Considerations

This module can be deployed at management group level.
To achieve this the principal deploying the template needs permission to deploy role Definition on the management group.

## Additional resources

- [Understand Azure role definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions)
- [Microsoft.Authorization roleDefinitions template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/2018-01-01-preview/roledefinitions)
