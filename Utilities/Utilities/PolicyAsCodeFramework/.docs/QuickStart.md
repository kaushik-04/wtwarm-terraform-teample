[[_TOC_]]

# Quick start guide

Before you proceed with the implementation, make sure you've read the following documents:

- **[Definitions](./Definitions.md)**
- **[Assignments](./Assignments.md)**

## Onboarding

To onboard the solution to your customer's environment, follow the below steps:

1. Make sure that there is a separate policy created for
   - `Components`
   - `Policies`

    This way, the duties around creating and assigning the policies can be separated.

2. Copy the folders in this solution to their respective repository and subfolder:
   - `Utilities/PolicyAsCodeFramework/Definitions` --> `Components/Policies`
   - `Utilities/PolicyAsCodeFramework/Assignments` --> `Policies/Assignments`

3. Optional: if it's not a green field setup, and the customer already has policies in use, run the `Get-StructuredPolicyAssignments.ps1` script to generate the assignments.json file based on the configuration of the existing environment. The user the script is run under, has to have permissions on each Management Group to read the policy assignments.

4. Create an Service Connection in Azure DevOps with the required permissions:
   - Create an AAD Service Principal (SPN).
   - Grant the required permissions to this SPN in Azure. Note that depending on your scenario, these permissions may be very high. If you're planning to use DeployIfNotExists policies, the SPN has to have owner rights on the scope of the assignment, so that it can grant access to the generated system assigned identity at deployment time. With other words, you may need Owner permission on Tenant Root group level to fully unlock all the capabilities of Azure policies and this solution.
   - The SPN will also need Azure Active `Directory reader` role. This is required both for the permission pre-flight check and for assigning permissions (for DeployIfNotExists policies) as the role assignment PowerShell commandlet requires this permission (if not granted, `CloudException` generic errors may rise)
   - Register the SPN in ADO as a Service Connection.

5. Configure definitions:
   - Register the Definitions pipeline (pipeline.yml in the `Policies` folder of the `Components` repository).
   - Populate the `PolicyDefinitions` and `InitiativeDefinitions` folders with custom definitions as per your requirements.
   - Trigger the Definitions pipeline either by pushing the changes, by a Pull request, or manually.

6. Configure assignments:
   - Register the Assignments pipeline (pipeline.yml in the `Assignments` folder in the `Policies` repository)
   - Populate/Update the content of the `assignments.json` file
   - Trigger the Assignments pipeline either by pushing the changes, by a Pull request, or manually.

[Return to the main page.](../readme.md)
