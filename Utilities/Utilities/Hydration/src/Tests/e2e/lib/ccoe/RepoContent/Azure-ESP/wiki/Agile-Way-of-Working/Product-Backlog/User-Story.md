> Click [here](https://dev.azure.com/contoso-azure/building-blocks/_backlogs/backlog/building-blocks%20Team/Backlog%20items/) to view the User Stories in our [Product Backlog](/Agile-Way-of-Working/Product-Backlog.md)

[[_TOC_]]

# Conventions

We will use User Stories to define the specific work that needs to be done to produce an increment of the related [Feature](/Agile-Way-of-Working/Product-Backlog/Feature.md).

User Stories must fit into any Sprint, and the increment must be shown in a demo during the [Sprint Review](/Agile-Way-of-Working/Events/Sprint-Review.md) session.

A good user story should follow the [INVEST](http://guide.agilealliance.org/guide/invest.html) formula:
- "I"ndependent (of all others)
- "N"egotiable (not a specific contract for features)
- "V"aluable (or vertical)
- "E"stimable (to a good approximation)
- "S"mall (so as to fit within an iteration)
- "T"estable (in principle, even if there isn’t a test for it yet)

The User Stories will be detailed with the following Work Item attributes:

| Attribute | Description
| - | -
| Title | The title of the User Story to enable. It describes *what* needs to be done with a short sentence that is extended in the description
| Tags | One or more of the agreed [tags](/Agile-Way-of-Working/Product-Backlog/Tags.md) related for this User Story 
| Description | The description of the User Story will follow the convention *"To achieve [why: reason/value], as a [who: persona] I want [what: increment to produce]"*. More details can be added to the User Story when needed
| State | One of the following [states](https://dev.azure.com/contoso-MS/_settings/process?process-name=ACF%20Process&type-id=Microsoft.VSTS.WorkItemTypes.UserStory&_a=states):<ul><li>**New**. The User Story does not contain enough information, and none of the child items can be considered for Sprint Planning</li><li>**Documented**. The User Story has been documented by the Product Owner, but it needs hasn't be discussed yet with the team in a [Backlog Refinement Session](/Agile-Way-of-Working/Events/Backlog-Refinement.md)</li><li>**Ready**. The User Story has been fully documented and understood by the team and criteria detailed in the section *Definition of Ready* is met, then it can be planned for a Sprint</li><li>**Committed**. Work related to this User Story has been planned for the current sprint</li><li>**Closed**. The User Story has been closed by the Product Owner during a [Sprint Review](/Agile-Way-of-Working/Events/Sprint-Review.md) after *Acceptance Criteria* and *Definition of Done* have been demoed and accepted</li></ul>
| Acceptance Criteria | The Acceptance Criteria as required by the [Product Owner](/Agile-Way-of-Working/Roles.md)

# Definition of Ready

We will mark a User Story as "Ready" when:
- All fields have been completed as described in the conventions above
- [Tags](/Agile-Way-of-Working/Product-Backlog/Tags.md) related to this User Story have been added
- There is a [Feature](/Agile-Way-of-Working/Product-Backlog/Feature.md) linked as parent to this User Story and with the "Ready" state
- The description has been documented following the User Story format as defined in the conventions above. Any other detailed other useful information can be added.
- Acceptance Criteria has been added
- Definition of Done applicable to the User Story have been added
- All members of the team agree that:
  - The User Story follows the [INVEST](http://guide.agilealliance.org/guide/invest.html) formula
  - The Acceptance Criteria and the Definition of Done describes [SMART](https://www.thoughtco.com/how-do-i-write-smart-goals-31493) goals
  - All members understand Acceptance Criteria and Definition of Done

# Definition of Done

The following Definition of Done have been agreed by the team at User Story level:

## Azure Resources configuration

1. The name of the resource follows the [naming convention](/Azure-Platform/Naming-Convention.md)
2. The resource is tagged according to our [tagging convention](/Azure-Platform/Resource-Tagging.md)
3. The resource is locked according to our [locking convention](/Azure-Platform/Resource-Locks.md)
4. Diagnostics and Activity logs are sent to the [Log Analytics workspace](/Azure-Platform/Azure-Subscriptions/ITC-Shared-Services/Monitor.md) or [Diagnostics Storage Account](/Azure-Platform/Azure-Subscriptions/ITC-Shared-Services/Storage.md)
5. This resource configuration and related operations are documented in the [Azure Platform Wiki](https://dev.azure.com/diplomatiebel-ict/Infrastructure/_wiki/wikis/Azure%20Platform%20Wiki/9/Azure-Platform)


# Components

1. Component has been documented according to our [Component Development](/Learning-resources/Infrastructure-as-Code/IaC-Modules/Module-Development.md) conventions
2. Component has been tested according to our [Component Development](/Learning-resources/Infrastructure-as-Code/IaC-Modules/Module-Development.md) conventions
3. Component has a cicd pipeline configured according to our [Component Development](/Learning-resources/Infrastructure-as-Code/IaC-Modules/Module-Development.md) conventions 

# User Stories in backlog

tbd: query to user stories in backlog

# User Stories to refine

tbd: query to user stories in backlog