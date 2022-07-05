> Click [here](https://dev.azure.com/contoso-azure/building-blocks/_backlogs/backlog/building-blocks%20Team/Epics) to view our Product Backlog    

[[_TOC_]]

# What is a Product Backlog?

> Learn about [Product Backlog](/Agile-Way-of-Working/Product-Backlog.md) in section [Learning resources](/Learning-resources.md)

The [product backlog](https://www.agilealliance.org/glossary/backlog) is the single authoritative source for things that a team works on. That means that nothing gets done that isn’t on the product backlog. Conversely, the presence of a product backlog item on a product backlog does not guarantee that it will be delivered. It represents an option the team has for delivering a specific outcome rather than a commitment.

![Product Backlog](/.attachments/images/Learning-resources/Agile/Scrum/product-backlog.png)

A team owns its product backlog and have a specific role, the **Product Owner**, with the primary responsibility for maintaining the product backlog. The key activities in maintaining the product backlog include prioritizing product backlog items, deciding which product backlog items should be removed from the product backlog, and facilitating product [backlog refinement](/Agile-Way-of-Working/Events/Backlog-Refinement.md).

# Product Backlog structure

![Backlog structure](/.attachments/images/Learning-resources/Agile/Scrum/epics-features-user-stories-tasks.png)

Product backlog items take a variety of formats, being [Epics](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops), [Features](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops) and [User Stories](https://www.agilealliance.org/glossary/user-stories/) being the most common. The team using the product backlog determines the format they chose to use and look to the backlog items as reminders of the aspects of a solution they may work on.

Using Epics and Features are one way we do mid-term to long-term planning. User Stories are functional increments into what the team divides up the work to be done in consultation with the customer or product owner.

## Epics

Epics are normally the way we first think of the users’ functional needs or features which need to be described in detail. On the product backlog, Epics are typically the highest-level grouping and are not used for estimation because they can’t really be "complete". Epics are normally large, cross-cutting, spanning multiple value areas, sprints, releases, and features, and can be improved over time by delivering more features.

[See here how we define our Epics](/Agile-Way-of-Working/Product-Backlog/Epic.md)

## Features

Features are the system-centric grouping level in the backlog and they describe what a system does. This is the level of detail that describes a block of functionality that delivers a new capability and should be defined sufficiently to be estimable and testable.

We try to ship features as a bundle of functionality. They should be small enough to fit in a release, but can span multiple sprints. Incomplete features do not allow users to realize value at all.

[See here how we define our Features](/Agile-Way-of-Working/Product-Backlog/Feature.md)

## User Stories

Each [user story](https://www.agilealliance.org/glossary/user-stories) is expected to yield, once implemented, a contribution to the value of the overall product, irrespective of the order of implementation; these and other assumptions as to the nature of user stories are captured by the [INVEST](http://guide.agilealliance.org/guide/invest.html) formula.

A good user story should be:
- "I"ndependent (of all others)
- "N"egotiable (not a specific contract for features)
- "V"aluable (or vertical)
- "E"stimable (to a good approximation)
- "S"mall (so as to fit within an iteration)
- "T"estable (in principle, even if there isn’t a test for it yet)

The whole point of taking User Stories on the project is to to bring actual project-related value to the stakeholder. Technical PBIs that are really fun to code but bring no value to the stakeholders are just that – of no value.

> *E.g. of User Story format: "To achieve [reason/value], as a [persona] I want [capability]"*

[See here how we define our User Stories](/Agile-Way-of-Working/Product-Backlog/User-Story.md)

## Tasks

Sprint tasks are used by teams to decompose user stories or product backlog items (PBIs) at the sprint planning meeting to a more granular level. A task should be completed by one person on the team, though the team may choose to pair up when doing the work.

Typically, each user story will have multiple associated tasks. Sometimes these will be created by function, such as design, code, test, document, or UX. Having tasks arranged in this manner allows team members to work in parallel on their area of functional expertise to complete the story as a team.

[See here how we define our Tasks](/Agile-Way-of-Working/Product-Backlog/Task.md)

# Product Backlog Mangament

[See here how we manage our Product Backlog](/Agile-Way-of-Working/Product-Backlog-management.md)

# References

1.  [Product Backlog | Agile Alliance](https://www.agilealliance.org/glossary/backlog)
2.  [Define features and epics | Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops)
3.  [User Stories | Agile Alliance](https://www.agilealliance.org/glossary/user-stories/)
4.  [INVEST Formula | Agile Alliance](https://www.agilealliance.org/glossary/invest)
5.  [How detailed should tasks within a user story be for agile teams?](https://techbeacon.com/app-dev-testing/how-detailed-should-tasks-within-user-story-be-agile-teams)