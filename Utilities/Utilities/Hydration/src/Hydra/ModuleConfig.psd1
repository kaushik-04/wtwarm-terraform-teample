@{
    #region general
    RegexGUID                                    = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
    RegexEmail                                   = '([.a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,})'

    # DevOps REST API
    PATCH_ContentType                            = 'application/json-patch+json'
    DEFAULT_ContentType                          = 'application/json'

    DevOpsPrincipalAppId                         = '499b84ac-1321-427f-aa17-267ca6975798' # 'Azure DevOps' Service Principal resourceAppId (fetched from app manifest in AAD)

    RESTPATCreate                                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/tokens/pats/create?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://vssps.dev.azure.com/{0}/_apis/tokens/pats?api-version=6.1-preview.1' # org
    }
    RESTPATList                                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/tokens/pats/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://vssps.dev.azure.com/{0}/_apis/tokens/pats?api-version=6.1-preview.1' # org
    }
    RESTPATRevoke                                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/tokens/pats/revoke?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://vssps.dev.azure.com/{0}/_apis/tokens/pats?authorizationId={1}&api-version=6.1-preview.1' # org, authorizationId
    }
    DEVOPS_PAT_NAME = 'devOpsHydrationPAT'
    DEVOPS_GIT_PAT_SCOPE = 'vso.code_write' # to read & write repo content
    #endregion

    #region Processes
    # ---------
    RESTProcessList                              = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/processes/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/process/processes?api-version=6.0'
    }
    RESTProcessCreate                            = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/processes/create?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes?api-version=6.1-preview.2' # org
    }
    RESTProcessRemove                            = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/processes/delete?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}?api-version=6.1-preview.2' # org, processTypeId
    }
    RESTProcessUpdate                            = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/processes/edit%20process?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}?api-version=6.1-preview.2' # org, processTypeId
    }
    RESTProcessWorkItemTypeList                  = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes?api-version=6.1-preview.2' # org, processid
    }
    RESTProcessWorkItemTypeCreate                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types/create?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes?api-version=6.1-preview.2' # org, processid
    }
    RESTProcessWorkItemTypeRemove                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types/delete?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes/{2}?api-version=6.1-preview.2' # org, processid, witRefName
    }
    RESTWorkItemTypeUpdate                       = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types/update?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes/{2}?api-version=6.1-preview.2' # org, processid, witRefName
    }
    RESTProcessWorkItemTypeStateList             = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/states/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states?api-version=6.1-preview.1' # org, processid, witRefName
    }
    RESTProcessWorkItemTypeStateCreate           = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/states/create?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states?api-version=6.1-preview.1' # org, processid, witRefName
    }
    RESTProcessWorkItemTypeStateRemove           = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/states/delete?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states/{3}?api-version=6.1-preview.1' # org, processid, witRefName, stateId
    }
    RESTProcessWorkItemTypeStateUpdate           = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/states/update?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states/{3}?api-version=6.1-preview.1' # org, processid, witRefName, stateId
    }
    RESTProcessBacklogLevelList                  = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/behaviors/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/behaviors?$expand=CombinedFields&api-version=6.1-preview.2' # org, processid
    }
    RESTProcessBacklogLevelCreate                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/behaviors/create?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/behaviors?api-version=6.1-preview.2'# org, processid
    }
    RESTProcessBacklogLevelRemove                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/behaviors/delete?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/behaviors/{2}?api-version=6.1-preview.2'# org, processid, behaviorRefName
    }
    RESTProcessBacklogLevelUpdate                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/behaviors/update?view=azure-devops-rest-6.1
        Method = 'PUT'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/behaviors/{2}?api-version=6.1-preview.2'# org, processid, behaviorRefName
    }

    RESTProcessWorkItemTypeBehaviorList          = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types%20behaviors/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors?api-version=6.1-preview.1'# org, processid, witRefName
    }
    RESTProcessWorkItemTypeBehaviorCreate        = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types%20behaviors/add?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors?api-version=6.1-preview.1'# org, processid, witRefName
    }
    RESTProcessWorkItemTypeBehaviorUpdate        = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/work%20item%20types%20behaviors/update?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors?api-version=6.1-preview.1'# org, processid, witRefName
    }
    #endregion

    #region Projects
    # --------------
    RESTProjectGet                               = @{
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}?api-version=6.0'
    }
    RESTProjectCreate                            = @{
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects?api-version=6.0'
    }
    RESTProjectUpdate                            = @{
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}?api-version=6.0'
    }
    RESTProjectRemove                            = @{
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}?api-version=6.0'
    }
    RESTProjectPropertiesGet                     = @{
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/properties?api-version=6.0-preview.1'
    }
    RESTProjectPropertiesSet                     = @{
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/properties?api-version=6.0-preview.1'
    }
    RESTProjectIconSet                           = @{
        Method = 'PUT'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/avatar?api-version=6.0-preview.1'
    }
    #endregion

    #region Classification Nodes (Area)
    # -------------------------------------
    RESTProjectAreaClassificationRootList        = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/get%20root%20nodes?view=azure-devops-rest-6.0
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/areas?depth=10&api-version=6.0'
    }
    RESTProjectAreaClassificationChildList       = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/get%20classification%20nodes?view=azure-devops-rest-6.0
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes?ids={2}&$depth=5&api-version=6.0'
    }
    RESTProjectAreaClassificationNodeRemove      = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/delete?view=azure-devops-rest-6.0
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Areas/{2}?api-version=6.0'
    }
    RESTProjectAreaClassificationNodeCreate      = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/create%20or%20update?view=azure-devops-rest-6.0
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Areas/{2}?api-version=6.0'
    }
    #endregion

    #region Classification Nodes (Iteration)
    # -------------------------------------
    RESTProjectIterationClassificationRootList   = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/get%20root%20nodes?view=azure-devops-rest-6.0
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Iterations?depth=10&api-version=6.0'
    }
    RESTProjectIterationClassificationChildList  = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/get%20classification%20nodes?view=azure-devops-rest-6.0
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes?ids={2}&$depth=5&api-version=6.0'
    }
    RESTProjectIterationClassificationNodeRemove = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/delete?view=azure-devops-rest-6.0
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Iterations/{2}?api-version=6.0'
    }
    RESTProjectIterationClassificationNodeCreate = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/create%20or%20update?view=azure-devops-rest-6.0
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Iterations/{2}?api-version=6.0'
    }
    RESTProjectIterationClassificationNodeUpdate = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/classification%20nodes/create%20or%20update?view=azure-devops-rest-6.1#move-an-iteration-node
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes/Iterations/{2}?api-version=6.0'
    }
    #endregion

    #region Repos
    # -----
    RESTRepositoriesList                         = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/get%20repository?view=azure-devops-rest-6.0
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories?api-version=6.0'
    }
    RESTRepositoriesCreate                       = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/create?view=azure-devops-rest-6.0
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories?api-version=6.0'
    }
    RESTRepositoriesRemove                       = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/delete?view=azure-devops-rest-6.0
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}?api-version=6.0'
    }
    DEVOPS_GIT_URL                               = "https://{0}@dev.azure.com/{1}/{2}/_git/{3}" # PAT, Org, Project, Repo

    #endregion

    #region Teams
    # -----
    RESTTeamCreate                               = @{
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/teams?api-version=6.0'
    }
    RESTTeamUpdate                               = @{
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/teams/{2}?api-version=6.0'
    }
    RESTTeamRemove                               = @{
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/teams/{2}?api-version=6.0'
    }
    RESTTeamList                                 = @{
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}/teams?api-version=6.0'
    }
    RESTTeamSettingsFieldValuesGet               = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/get?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings/teamfieldvalues?api-version=6.0' # org, project, team
    }
    RESTTeamSettingsFieldValuesSet               = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/teamfieldvalues/update?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings/teamfieldvalues?api-version=6.0' # org, project, team
    }
    RESTTeamSettingsGet                          = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/get?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings?api-version=6.1-preview.1' # org, project, team
    }
    RESTTeamSettingsSet                          = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/teamsettings/update?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings?api-version=6.1-preview.1' # org, project, team
    }

    RESTeamBoardGet                              = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/boards/get?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/boards/{3}?api-version=6.1-preview.1' # org, project, team, boardId/name
    }
    RESTeamBoardRowsSet                          = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/rows/update?view=azure-devops-rest-6.1
        Method = 'PUT'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/boards/{3}/rows?api-version=6.1-preview.1' # org, project, team, boardId/name
    }
    RESTeamBoardColumnsSet                       = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/columns/update?view=azure-devops-rest-6.1
        Method = 'PUT'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/boards/{3}/columns?api-version=6.1-preview.1' # org, project, team, boardId/name
    }

    RESTTeamSettingsIterationsGet                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/iterations/list?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings/iterations?api-version=6.1-preview.1' # org, project, team
    }
    RESTRestSettingsIterationsAdd                = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/iterations/post%20team%20iteration?view=azure-devops-rest-6.1
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings/iterations?api-version=6.1-preview.1' # org, project, team
    }
    RESTRestSettingsIterationsRemove             = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/iterations/delete?view=azure-devops-rest-6.1
        Method = 'DELETE'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/teamsettings/iterations/{3}?api-version=6.1-preview.1' # org, project, team, iterationid
    }
    RESTTeamProjectDefaultUpdate                 = @{
        # Reverse engineered via development console
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1' # org
    }

    RESTeamCardRuleSettingsGet                   = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/cardrulesettings/get?view=azure-devops-rest-6.1
        Method = 'GET'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/boards/{3}/cardrulesettings?api-version=6.1-preview.2' # org, project, team, boardId/name
    }
    RESTeamCardRuleSettingsSet                   = @{
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/work/cardrulesettings/update%20board%20card%20rule%20settings?view=azure-devops-rest-6.1
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/{1}/{2}/_apis/work/boards/{3}/cardrulesettings?api-version=6.1-preview.2' # org, project, team, boardId/name
    }

    RegexCardRuleSettingsFillFilter              = '\[(.+?)\]'
    cardRuleSettingsFillBackgroundColorDefault   = '#de5e5e'
    cardRuleSettingsFillForegroundColorDefault   = '#000000'
    cardRuleSettingsTagStyleColorDefault         = '#000000'
    #endregion

    #region Backlog
    # -------------
    RESTBoardBatchSet                            = @{
        Method = 'PATCH'
        Uri    = 'https://dev.azure.com/{0}/_apis/wit/$batch?api-version=6.0' # Org
    }
    RESTBoardWorkItemCreate                      = @{
        Method = 'PATCH'
        Uri    = '/{0}/_apis/wit/workitems/${1}?api-version=6.0' # Project | WorkItemType
    }
    RESTBoardWorkItemUpdate                      = @{
        Method = 'PATCH'
        Uri    = '/_apis/wit/workitems/{0}?api-version=6.0' # WorkItemId
    }
    RESTBoardWorkItemRemove                      = @{
        Method = 'DELETE'
        Uri    = '/_apis/wit/workitems/{0}?api-version=6.0' # WorkItemId
    }
    RESTBoardWorkItemRecycleBinRemove            = @{
        Method = 'DELETE'
        Uri    = '/_apis/wit/recyclebin/{0}?api-version=6.0' # WorkItemId
    }
    RESTBoardWorkItemRelationAdd                 = @{
        Uri = 'https://dev.azure.com/{0}/_apis/wit/workItems/{1}' # Org | WorkItemId
    }
    RESTBoardWorkItemGetWiql                     = @{
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/wiql?api-version=6.0' # Org | Project
    }
    RESTBoardWorkItemGetBatch                    = @{
        Method = 'POST'
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/workitemsbatch?api-version=6.1-preview.1' # Org | Project
    }

    BoardBatchReponseSuccess                     = @('200', '204')
    BoardBatchCapacity                           = 200 # DO NOT CHANGE. This is the maxmium number of requests the API can handle and results it returns (excluding WIQL)
    #endregion
}