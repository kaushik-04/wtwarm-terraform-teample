[[_TOC_]]
# Overview of Component development process

![Diagram of certified component publishing](/.attachments/images/Certified-Components/certified-components-publishing.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

The process for publishing a Certified Component consists of the following steps:
1. [Design](/Certified-Components/Component-development/Design.md) the Certified Component
2. [Develop](/Certified-Components/Component-development/Develop.md) the Certified Component according to the Design, including:
   - The reusable ARM Template or PowerShell Script that will allow to deploy the Certified Component declaratively
   - The Azure Policies that will guarantee that the resource is configured according to the Design Decisions
   - A README.md file with implementation details and usage guidelines
3. [Test and package](/Certified-Components/Component-development/Test-and-Package.md) the Certified Component
4. [Publish](/Certified-Components/Component-development/Publish.md) the Certified Component, which includes:
   - Package the tested ARM Template or PowerShell Script and publish into an Azure DevOps Artifact
   - Publish the developed policies so that they start taking effect in the Landing Zones
   - Publish the documentation

## Design

> Learn more in the section [Design](/Certified-Components/Component-development/Design.md)

## Develop

> Learn more in the section [Develop](/Certified-Components/Component-development/Develop.md)

## Test and Package

> Learn more in the section [Test and Package](/Certified-Components/Component-development/Test-and-Package.md)

## Publish

> Learn more in the section [Publish](/Certified-Components/Component-development/Publish.md)