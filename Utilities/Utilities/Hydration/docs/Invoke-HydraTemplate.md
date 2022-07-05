---
external help file: Hydra-help.xml
Module Name: Hydra
online version: https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows
schema: 2.0.0
---

# Invoke-HydraTemplate

## SYNOPSIS
Invokes the hydration given the definition file.
Creates Azure DevOps resources based on a hydration defintion file that matches a given schema.

## SYNTAX

```
Invoke-HydraTemplate [-Path] <String> [-Force] [-SkipLogin] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invokes the hydration given the definition file.
In order to invoke the hydration make sure to follow these steps:

1.
Run \`Get-AzHydrationSchema\` and create a definition file based on the given JSON schema you can find an example in \[hydrationDefinition.json\](./src/Tetss/hydrationDefinition.json)
2.
Run \`Test-AzHydrationTemplate\` to validate the create definition tempalte against the schema
3.
Run \`Invoke-AzHydrationTemplate\` to run the actual hydration
4.
Login using a personal access token.
If you want to use Azure Active Directory run with \`-SkipLogin\`.
Make sure you are authenticated.

The \`Invoke-AzHydrationTemplate\` will create Azure DevOps resources based on a hydration defintion file that matches a given schema.
The module uses the extension 'azure-devops' and installs it if misisng.

## EXAMPLES

### EXAMPLE 1
```
Invoke-HydraTemplate -Path $path
                      
Extension 'azure-devops' is already installed.
Token: 
TODO: input output of actual execution
```

### EXAMPLE 2
```
Invoke-HydraTemplate -Path $path -SkipLogin
                      
Extension 'azure-devops' is already installed.
TODO: input output of actual execution
```

## PARAMETERS

### -Force
ATTENTION!
Forces the replacement of exsiting resources.
Make sure to validate the defintiion file before applying it using \`-Force\`.
Deletes exsisting resource before recreating the ones specified in the defintion file.
Make sure to backup exsiting resources before applying them with force.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to the definition template file.
The defintion tempalte file can be tested against a schema using \`Test-AzHydrationTemplate\`.
The schema for the definition file can be generated using \`Get-AzHydrationSchema\`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipLogin
Skip the login and uses cached credentials.
Make sure you run \`az devops login\` previous to running \`Invoke-AzHydrationTempalte -SkipLogin\`.
Follow https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows to Sign in with a Personal Access Token

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS

[https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows)

