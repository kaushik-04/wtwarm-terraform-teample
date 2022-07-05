[[_TOC_]]

# What are Azure Resource Manager (ARM) templates?

With the move to the cloud, many teams have adopted agile development methods. These teams iterate quickly. They need to repeatedly deploy their solutions to the cloud, and know their infrastructure is in a reliable state. As infrastructure has become part of the iterative process, the division between operations and development has disappeared. Teams need to manage infrastructure and application code through a unified process.

To meet these challenges, you can automate deployments and use the practice of infrastructure as code. In code, you define the infrastructure that needs to be deployed. The infrastructure code becomes part of your project. Just like application code, you store the infrastructure code in a source repository and version it. Any one on your team can run the code and deploy similar environments.

To implement infrastructure as code for your Azure solutions, use [Azure Resource Manager (ARM) templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview). The template is a JavaScript Object Notation (JSON) file that defines the infrastructure and configuration for your project. The template uses declarative syntax, which lets you state what you intend to deploy without having to write the sequence of programming commands to create it. In the template, you specify the resources to deploy and the properties for those resources.

In its simplest [structure](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax), a template has the following elements:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "",
  "apiProfile": "",
  "parameters": {  },
  "variables": {  },
  "functions": [  ],
  "resources": [  ],
  "outputs": {  }
}
```

| Element name | Required | Description
| - | - | -
| `$schema` | Yes | Location of the JSON schema file that describes the version of the template language. The version number you use depends on the scope of the deployment and your JSON editor. <ul><li>If you're using [VS Code with the Azure Resource Manager tools extension](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-templates-use-visual-studio-code), use the latest version for resource group deployments: `https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#` </li><li>Other editors (including Visual Studio) may not be able to process this schema. For those editors, use: `https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#`</li><li>For subscription deployments, use: `https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#`</li><li>For management group deployments, use: `https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#`</li><li> For tenant deployments, use: `https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#` </li></ul>
| `contentVersion` | Yes |Version of the template (such as 1.0.0.0). You can provide |any value for this element. Use this value to document significant changes in |your template. When deploying resources using the template, this value can be |used to make sure that the right template is being used.
| `apiProfile` | No | An API version that serves as a collection of API versions for resource types. Use this value to avoid having to specify API versions for each resource in the template. When you specify an API profile version and don't specify an API version for the resource type, Resource Manager uses the API version for that resource type that is defined in the profile. <br><br> The API profile property is especially helpful when deploying a template to different environments, such as Azure Stack and global Azure. Use the API profile version to make sure your template automatically uses versions that are supported in both environments. For a list of the current API profile versions and the resources API versions defined in the profile, see [API Profile](https://github.com/Azure/azure-rest-api-specs/tree/master/profile). <br>For more information, see [Track versions using API profiles](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/templates-cloud-consistency#track-versions-using-api-profiles).
| [`parameters`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax#parameters) | No | Values that are provided when deployment is executed to customize |resource deployment.
| [`variables`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax#variables) | No | Values that are used as JSON fragments in the template to simplify template language expressions.
| [`functions`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax#functions) | No | User-defined functions that are available within the template.
| [`resources`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax#resources) | Yes | Resource types that are deployed or updated in a resource group or subscription.
| [`outputs`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax#outputs) | No | Values that are returned after deployment.

For ARM Template deployment, rather than passing parameters as inline values in your script, you may find it easier to use a JSON file that contains the parameter values.

The [parameter file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameter-files) has the following format:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "<first-parameter-name>": {
      "value": "<first-value>"
    },
    "<second-parameter-name>": {
      "value": "<second-value>"
    }
  }
}
```

The following parameter file includes a plain text value and a value that is [stored in a key vault](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter).

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "<first-parameter-name>": {
      "value": "<first-value>"
    },
    "<second-parameter-name>": {
      "reference": {
        "keyVault": {
          "id": "<resource-id-key-vault>"
        },
        "secretName": "<secret-name>"
      }
    }
  }
}
```

# Learning Resources

1. [Tutorial: Create and deploy your first ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template?tabs=azure-powershell)

# References

## ARM design

1. [Resources portal](https://resources.azure.come)
6. [ARM Reference](https://docs.microsoft.com/en-us/azure/templates/)
7. [Azure REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/)
8. [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)

## ARM Templates authoring

**Basics**

1. [Azure Resource Manager templates overview](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
2. [Structure and Syntax](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)
3. [Azure resource providers and types](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
4. [Create Resource Manager parameter file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameter-files)
5. [Define child resource in Azure template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-template-child-resource?toc=%2fazure%2ftemplates%2ftoc.json&bc=%2Fazure%2Ftemplates%2Fbreadcrumb%2Ftoc.json)

**Advanced**

8. [Functions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions)
9. [Resource iteration](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-multiple#resource-iteration)
10. [Conditionally deploy resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-templates-resources#condition)
11. [Dependency](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-define-dependencies)

**Tools**

1. [Use Visual Studio Code to create Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/use-vs-code-to-create-template)

## ARM Templates modularization

12. [Linked templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-linked-templates)

## ARM Templates secrets management

1. [Key Vault secret with ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter)

## ARM Templates testing

1. [Azure Resource Manager Template Toolkit (arm-ttk)](https://github.com/Azure/arm-ttk)
2. [Pester](https://pester.dev/)
3. [Pester Quick Start](https://pester.dev/docs/quick-start)
4. [What is Pester and Why Should I Care?](https://devblogs.microsoft.com/scripting/what-is-pester-and-why-should-i-care/)

## ARM Templates deployment

1. [View deployment history with Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-history?tabs=azure-portal)

### PowerShell

1. [Deploy resources with Resource Manager templates and Azure PowerShell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
2. [Use deployment scripts in templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI)

### Azure DevOps

1. [Integrate ARM templates with Azure Pipelines](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/add-template-to-azure-pipelines)
2. [Task groups for builds and releases](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/task-groups?view=azure-devops)