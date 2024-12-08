# Azure App Configuration Sync

Azure App Configuration Sync of Properies and Feature Flags using Azure CLI.

## Inputs
| Name               | Mandatory | Default         | Description                                    |
|--------------------|-----------|-----------------|------------------------------------------------|
| configurationFile | true | None | Path to the configuration file in the repo, relative to the repo root. Also supports glob patterns and multiple files |
| connectionString | true | None | Connection string for the App Configuration instance |
| format | true | None | Format of the configuration file. Valid values are: json, yaml, properties |
| contentType | false | keyvalue | Content type for the values. Valid values are: 'keyvalue' (default), 'keyvaultref' or 'featureflag' |
| label | false | \0 | Label to use when setting the key-value pairs. If not specified, a null label will be used |
| prefix | false | None | Prefix that will be added to the front of the keys |
| separator | false | . | Separator used when flattening the configuration file to key-value pairs (only for json and yaml format files, defaults to '.') |
| strict | false | None | Specifies whether to use a strict sync which will make the App Configuration instance exactly match the configuration file (deleting key-values not in the configuration file). Defaults to false |
| tags | false | None | Stringified form of a JSON object with the following shape: { [propertyName: string]: string; } |

## Outputs
| Name               | Description                                    |
|--------------------|------------------------------------------------|
| changes_applied | Indicates whether changes were applied during the sync process. |

## Steps
| Step ID            | Step Name                                      |
|--------------------|------------------------------------------------|
| setup-path | Setup Script and GitHub Path |
| setup-args | Setup Script Args |
| check-binaries | Check Prerequisite Binaries |
| validate-inputs | Validate Inputs |
| sync-config | Sync with Azure App Configuration |
