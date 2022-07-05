This section describes the **Product Certification Process** workflow and procedure for CCoE certified products consumed by its customers (the BizDevOps teams). It described the procedure of the deployment fase in the following high-level process.

![Certification process.png](/.attachments/Certification%20process-8570a2fe-e6c4-493a-a039-57c1f4bd5374.png)


The above diagram shows all the steps in the development phase and lifetime of a **Certified Azure Product**.

1. The first step is defining the Vision for the reusable Product to develop and certify. The Vision defines the requirements for the Product from a business, technical and security requirements perspective. We capture the description and requirements in the Product Description (in the [Product Catalog](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog)).
1. As soon the Product(s) are defined, the CCoE DevOps team puts the product as a PBI in the backlog. During this process, the security team investigates which security controls are required for the specific workload. These controls are described on high level (as “What” statements) and must now be translated to product specific implementation measures: the “How”. Together with the Architect, the security team translates the requirement to an Azure technical solution and the requirement and settings to accomplish the desired Security configuration are documented together with the technical documentation in the product description in the [Product Catalog.](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog)
1. As soon all requirements are documented in the product description of the product in the [product catalog](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog), and the security requirements are reflected in the PBI by tasks, they will be onboarded in a specific Sprint Backlog.
1. During the Sprint, the DevOps team will develop the workload as Infrastructure as Code (IaC).
1. At the end of the sprint, the PBI owner will present the developed workload in a full deployment scenario in a Demo production Landing Zone (including all security policies). The presentation of the workload will include all the security related requirements implemented. During this demo, the Security team need to validate, based on the requirements defined during step 2 , if all security requirements are met.
1. After the demo in the sprint review, the Security team together with the Product owner will check the approvals performed during the sprint review and check if the solution is applicable for production deployment.
1. If the full process is successful delivered, the Product owner can certify the Workload. The procedure how to publish and protect the certified product is described [here](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/510/Component-publishing).

The Process of developing a workload works on the principle of the Lean Product Development, which is the process for building products faster with less waste using **Minimum Valuable Product (MVP)**.

<IMG  src="https://blog.bonzertech.com/wp-content/uploads/2016/01/MVP2.png"  alt="See the source image"/>