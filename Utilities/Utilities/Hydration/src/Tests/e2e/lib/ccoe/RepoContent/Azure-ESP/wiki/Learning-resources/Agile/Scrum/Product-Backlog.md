[[_TOC_]]

# What is a Product Backlog?

The [product backlog](https://www.agilealliance.org/glossary/backlog) is the single authoritative source for things that a team works on. That means that nothing gets done that isn’t on the product backlog. Conversely, the presence of a product backlog item on a product backlog does not guarantee that it will be delivered. It represents an option the team has for delivering a specific outcome rather than a commitment.

![Product Backlog](/.attachments/images/Learning-resources/Agile/Scrum/product-backlog.png =30%x)

A team owns its product backlog and have a specific role, the **Product Owner**, with the primary responsibility for maintaining the product backlog. The key activities in maintaining the product backlog include prioritizing product backlog items, deciding which product backlog items should be removed from the product backlog, and facilitating product [backlog refinement](/Learning-resources/Agile/Scrum/Events/Backlog-Refinement.md).

# Product Backlog structure

Product backlog items take a variety of formats, being [Epics](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops), [Features](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops) and [User Stories](https://www.agilealliance.org/glossary/user-stories/) the most common. The team using the product backlog determines the format they chose to use and look to the backlog items as reminders of the aspects of a solution they may work on.

Using Epics and Features are one way we do mid-term to long-term planning. User Stories are functional increments into what the team divides up the work to be done in consultation with the customer or product owner.

![Epics, Features, User Stories and Tasks](/.attachments/images/Learning-resources/Agile/Scrum/epics-features-user-stories-tasks.png)

## Epics

Epics are normally the way we first think of the users’ functional needs or features which need to be described in detail. On the product backlog, Epics are typically the highest-level grouping and are not used for estimation because they can’t really be "complete". Epics are normally large, cross-cutting, spanning multiple value areas, sprints, releases, and features, and can be improved over time by delivering more features.

![What are epics](/.attachments/images/Learning-resources/Agile/Scrum/epics.png =500x)

## Features

Features are the system-centric grouping level in the backlog and they describe what a system does. This is the level of detail that describes a block of functionality that delivers a new capability and should be defined sufficiently to be estimable and testable.

We try to ship features as a bundle of functionality. They should be small enough to fit in a release, but can span multiple sprints. Incomplete features do not allow users to realize value at all.

![What are features](/.attachments/images/Learning-resources/Agile/Scrum/features.png =500x)

## User Stories

Each [user story](https://www.agilealliance.org/glossary/user-stories) is expected to yield, once implemented, a contribution to the value of the overall product, irrespective of the order of implementation; these and other assumptions as to the nature of user stories are captured by the [INVEST](http://guide.agilealliance.org/guide/invest.html) formula.

![Functional requirements vs User Stories](/.attachments/images/Learning-resources/Agile/Scrum/functional-requirements-vs-user-stories.png =60%x)

A good user story should be:
- **I**ndependent (of all others)
- **N**egotiable (not a specific contract for features)
- **V**aluable (or vertical)
- **E**stimable (to a good approximation)
- **S**mall (so as to fit within an iteration)
- **T**estable (in principle, even if there isn’t a test for it yet)

The whole point of taking User Stories on the project is to to bring actual project-related value to the stakeholder. Technical PBIs that are really fun to code but bring no value to the stakeholders are just that – of no value.

> *E.g. of User Story format: "To achieve [outcome/value], as a [persona], I want [capability]"*

## Tasks

Sprint tasks are used by teams to decompose user stories or product backlog items (PBIs) at the sprint planning meeting to a more granular level. A task should be completed by one person on the team, though the team may choose to pair up when doing the work.

Typically, each user story will have multiple associated tasks. Sometimes these will be created by function, such as design, code, test, document, or UX. Having tasks arranged in this manner allows team members to work in parallel on their area of functional expertise to complete the story as a team.

# Release Plan

Release Planning is one way we gather enough detail to do high-level planning. The release plan is a tool that allows for discussion to align targets, estimates, and joint commitments over a medium-long time range. The plan is reviewed at least quarterly in terms of Epics and Features (Stories are too granular).

How:
- Define a release goal and the project vision
- Select an iteration length, perform estimation and prioritization of user stories (there is always too much to do in too little time)
- Select features and a release date, use "what-if" questions to estimate delivered scope

# Prioritization

Items in Product Backlog must always have a priority, and the Product Owner is the the responsible of continuously setting a priority for the items in  the Product Backlog.

MoSCow prioritization based on Business Viability, Technical Feasibility and User Desirability combined with Design Thinking helps Product Owners identify what to work on first (see above, in the *what* section).

![MoSCow Prioritization](/.attachments/images/Learning-resources/Agile/Scrum/Product-Backlog/moscow-prioritization.png =50%x)

# Definition of Ready

[Definition of Ready](https://www.agilealliance.org/glossary/definition-of-ready/) is a set of agreements decided by the team that describes when a work item is ready to be worked on.

Definition of Ready avoids beginning work on features that do not have clearly defined completion criteria, which usually translates into costly back-and-forth discussion or rework. It also provides the team with an explicit agreement allowing it to “push back” on accepting ill-defined features to work on.

Examples of Definition of Ready:
- Details are sufficiently understood by the development team so it can make an informed decision as to whether it can complete the backlog item
- Dependencies are identified and no external dependencies would block the backlog item from being completed
- The backlog item is estimated and small enough to comfortably be completed in one sprint
- Acceptance criteria are clear and testable
- Team understands how to demonstrate the backlog item at the sprint review

# Acceptance Criteria

[Acceptance Criteria](https://www.leadingagile.com/2014/09/acceptance-criteria/) are the conditions that a product increment must satisfy to be accepted by a user, customer, or in the case of system level functionality, the consuming system.

Acceptance Criteria are a set of statements, each with a clear pass/fail result, that specify both functional and non-functional requirements, and are applicable at the Epic, Feature, and Story Level.

Express Acceptance Criteria clearly, in simple language the customer would use, without ambiguity regarding the expected outcome. This sets our testers up for success, since they will be taking our criteria and translating them into automated test cases to run as part of our continuous integration build.

Criteria should state intent, but not a solution. (e.g., “User can approve or reject an invoice” rather than “User can click a checkbox to approve an invoice”). The criteria should be independent of the implementation, and discuss WHAT to expect, and not HOW to implement the functionality.

The Given/When/Then format is helpful way to specify criteria:

> **Given** *some precondition* **When** *I do some action* **Then** *I expect some result*

When writing acceptance criteria in this format, it provides a consistent structure. Additionally, it helps testers determine when to begin and end testing for that specific work item.

However, depending on the nature of the User Story/Feture/Epic, sometimes it’s difficult to construct criteria using the given, when, then, format. In those cases, verification checklist works well.

# Definition of Done

[Definition of Done](https://www.agilealliance.org/glossary/definition-of-done/) is a set of agreements decided by the team that describes when a work item may be closed on top of Acceptance Criteria.

The Definition of Done provides a checklist which usefully guides pre-implementation activities: discussion, estimation, design. It also limits the cost of rework once a feature has been accepted as “done”.

Having an explicit contract limits the risk of misunderstanding and conflict between the development team and the customer or product owner.

Examples of Definition of Done:
- Functionality tested in all environments, ready to go live
- Functionality is documented in wiki
- Code reviewed by a team member
- Demo is prepared to be shown in sprint review

![Definition of Done and Acceptance criteria](/.attachments/images/Learning-resources/Agile/Scrum/definition-of-done-and-acceptance-criteria.png =60%x)

# References

1.  [Product Backlog | Agile Alliance](https://www.agilealliance.org/glossary/backlog)
2.  [Define features and epics | Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops)
3.  [User Stories | Agile Alliance](https://www.agilealliance.org/glossary/user-stories/)
4.  [INVEST Formula | Agile Alliance](https://www.agilealliance.org/glossary/invest)
5.  [How detailed should tasks within a user story be for agile teams?](https://techbeacon.com/app-dev-testing/how-detailed-should-tasks-within-user-story-be-agile-teams)
6.  [Definition of Ready | Agile Alliance](https://www.agilealliance.org/glossary/definition-of-ready/)
7.  [Definition of Done | Agile Alliance](https://www.agilealliance.org/glossary/definition-of-done/)
8.  ["Acceptance Criteria", by Steve Povilaitis | Leading Agile](https://www.leadingagile.com/2014/09/acceptance-criteria/)