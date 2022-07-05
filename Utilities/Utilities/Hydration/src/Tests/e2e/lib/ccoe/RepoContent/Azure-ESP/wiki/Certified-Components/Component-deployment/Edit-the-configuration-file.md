[[_TOC_]]

# Overview

In order to take advantages of the benefits of [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md) we need to keep the files that describe the configuration of our infrastructure in source control.

The Certified Components are [designed](/Certified-Components/Design-principles.md) to read configuration from one declarative configuration file and then deploy or change the target resource in Azure accordingly to this configuration.

# Checklist

- [X] Read the `README.md` documentation of the Certified Component to understand the properties that you can configure in our configuration file for each Certified Component.
- [X] [Create or edit the configuration file](#configuration-file-for-certified-component) and configure it as desired

# Guidance
## Configuration file for Certified Component

Certified Components will have a [module deployment script](/Learning-resources/Infrastructure-as-Code.md) responsible for reading the configuration file and deploy the ARM Template or PowerShell scripts required to deploy and configure the infrastructure.

The configuration file will follow [ARM Template syntax](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md) for parameters.

E.g.
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
Each Certified Component will contain in their [README.md](/Certified-Components/Design-principles.md) file a schema that can be used to edit the configuration file and all possible configurations. 

# References

1. [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md)
2. [Certified Component Design Principles](/Certified-Components/Design-principles.md)
3. [Repository strategy for Certified Components deployment](/Certified-Components/Component-versioning.md)
4. [ARM Template syntax](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md)
