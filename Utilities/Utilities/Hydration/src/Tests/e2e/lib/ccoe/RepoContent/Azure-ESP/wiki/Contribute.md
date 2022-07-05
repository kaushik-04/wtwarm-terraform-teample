[[_TOC_]]

# What is a Wiki

[Wiki](https://docs.microsoft.com/en-us/azure/devops/project/wiki/about-readme-wiki?view=azure-devops) is a fantastic tool to enable collaboration across teams while keeping a healthy documentation and a single source of truth. 

Wiki is a composition system; it's a discussion medium; it's a repository; it's a mail system; it's a tool for collaboration. Wiki it's a fun way to communicate asynchronously across the network.

Wikis are great ways to:
1. Share information 
2. Create public projects
3. Content Versioning
4. Collaborate with team members/stakeholders

# How you can contribute to this Wiki

Technically speaking, Azure DevOps Wikis are Git Repositories with Markdown files that allow you to add rich formatted text, tables, images, videos and HTML.

Since Wikis are Git Repos, you can edit the content of the Wiki using different approaches:
- Using the **Azure DevOps Wiki Editor** you can edit the content of the wiki through using Azure DevOps graphical interface. Follow the instructions [here](https://docs.microsoft.com/en-us/azure/devops/project/wiki/add-edit-wiki?view=azure-devops&tabs=browser) for further guidance.
- Using **Git** you can clone this Wiki repository, add changes, commit those changes and push back to Wiki branch. Follow the instructions [here](https://docs.microsoft.com/en-us/azure/devops/project/wiki/wiki-update-offline?view=azure-devops) for further guidance.

You must take a few things into consideration in order to work with Azure DevOps Wikis:
- For a Repository to become a Wiki, you need to follow a specific structure of files and folders and follow a naming convention. You can find all the details in the [Azure DevOps documentation](https://docs.microsoft.com/en-us/azure/devops/project/wiki/wiki-file-structure?view=azure-devops)
- Same as in Git Repositories, you can protect the master branch of the Wiki so that only approved and review modifications are allowed. If the Wiki is protected, you need to add changes by creating your feature branch and using Pull Requests to merge changes.

## About Markdown

The Wiki uses the [Markdown](https://en.wikipedia.org/wiki/Markdown) language.

Here you can find useful references to master markdown:
- [Syntax guidance for basic Markdown usage](https://docs.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops)
- [Syntax guidance for Markdown usage in Wiki](https://docs.microsoft.com/en-us/azure/devops/project/wiki/wiki-markdown-guidance?view=azure-devops)
- [Basic writing and formatting syntax](https://help.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax)
- [Mastering Markdown](https://guides.github.com/features/mastering-markdown/)
- [Emoji Cheat Sheet](https://www.webfx.com/tools/emoji-cheat-sheet/)

# How to start discussions

You will find a discussion thread at the bottom of any wiki page. You can suggest changes or start discussions by adding comments to this discussions thread.

To do so, simply add a [markdown-based comment](https://docs.microsoft.com/en-us/azure/devops/project/wiki/add-comments-wiki?view=azure-devops). You can @mention users and groups. This @mention sends an email notification to each user or group, with a link to the wiki page.