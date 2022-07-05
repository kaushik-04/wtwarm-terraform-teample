# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Backlog] Board Item validation" -Tag Unit {

        $testCases = @(
            @{
                # VALID
                backlogItem  = @{
                    'ID'             = ''
                    'Title 1'        = 'Epic 1'
                    'Title 2'        = ''
                    'Title 3'        = ''
                    'Relation'       = ''
                    'Work Item Type' = 'Epic'
                }
                elementIndex = 2
                Expected     = $true
            },
            @{
                # INVALID - NO TITLE
                backlogItem  = @{
                    'ID'             = ''
                    'Title 1'        = ''
                    'Title 2'        = ''
                    'Title 3'        = ''
                    'Work Item Type' = 'Epic'
                }
                elementIndex = 1
                Expected     = $false
            },
            @{
                # INVALID - NON-EXISTING RELATION
                backlogItem  = @{
                    'ID'             = ''
                    'Title 1'        = 'Epic 1'
                    'Title 2'        = ''
                    'Title 3'        = ''
                    'Relation'       = 'nonexitent'
                    'Work Item Type' = 'Epic'
                }
                elementIndex = 3
                Expected     = $false
            },
            @{
                # INVALID - NON-EXISTING ITEM TYPE
                backlogItem  = @{
                    'ID'             = ''
                    'Title 1'        = 'Epic 1'
                    'Title 2'        = ''
                    'Title 3'        = ''
                    'Relation'       = 'Related'
                    'Work Item Type' = 'nonexitent'
                }
                elementIndex = 3
                Expected     = $false
            },
            @{
                # INVALID - NON-MATCHING STATE
                backlogItem  = @{
                    'ID'             = ''
                    'Title 1'        = 'Epic 1'
                    'Title 2'        = ''
                    'Title 3'        = ''
                    'State'          = 'New'
                    'Work Item Type' = 'Epic'
                }
                elementIndex = 3
                Expected     = $false
            }
        )

        It "Test Board item" -TestCases $testCases {

            param (
                [PSCustomObject] $backlogItem,
                [int] $elementIndex,
                [string] $expected
            )
            $res = Confirm-BacklogItem -backlogItem $backlogItem -elementIndex $elementIndex -ErrorAction 'SilentlyContinue'
            $res | Should -Be $false
        }
    }
}