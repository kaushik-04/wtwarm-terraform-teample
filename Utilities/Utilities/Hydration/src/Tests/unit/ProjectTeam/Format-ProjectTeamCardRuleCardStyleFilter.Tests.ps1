# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Team] Format-ProjectTeamCardRuleCardStyleFilter" {

        It "Should format local" {
            $res = Format-ProjectTeamCardRuleCardStyleFilter -localFilter "[Tags] contains 'Blocked' and [StoryPoints] = '8'" -ErrorAction 'Stop'
            $res | Should -Be "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"
        }

        It "Should format local with spaces" {
            $res = Format-ProjectTeamCardRuleCardStyleFilter -localFilter "[Tags] contains 'Blocked' and [Story Points] = '8'" -ErrorAction 'Stop'
            $res | Should -Be "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"
        }

        It "Should format local with system value" {
            $res = Format-ProjectTeamCardRuleCardStyleFilter -localFilter "[System.Tags] contains 'Blocked' and [StoryPoints] = '8'" -ErrorAction 'Stop'
            $res | Should -Be "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"
        }

        It "Should format remote" {
            $res = Format-ProjectTeamCardRuleCardStyleFilter -remoteFilter "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'" -ErrorAction 'Stop'
            $res | Should -Be "[Tags] contains 'Blocked' and [Story Points] = '8'"
        }
    }
}