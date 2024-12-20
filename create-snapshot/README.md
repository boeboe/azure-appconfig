# Azure App Configuration Create Snapshot

Creates a snapshot in Azure App Configuration using Azure CLI.

## Inputs
| Name               | Mandatory | Default         | Description                                    |
|--------------------|-----------|-----------------|------------------------------------------------|
| connectionString | true | None | Connection string for the App Configuration instance. |
| name | true | None | Name of the snapshot to be created. |
| filters | true | None | Space-separated list of escaped JSON objects representing key and label filters. |
| compositionType | false | key | Composition type for building the snapshot. Valid values are: key or key_label. Defaults to 'key'. |
| retentionPeriod | false | None | Duration in seconds for which the snapshot can remain archived before expiry. |
| tags | false | None | Stringified form of a JSON object with the following shape: { [propertyName: string]: string; } |

## Outputs
| Name               | Description                                    |
|--------------------|------------------------------------------------|

## Steps
| Step ID            | Step Name                                      |
|--------------------|------------------------------------------------|
| Unnamed ID | Setup Script and GitHub Path |
| Unnamed ID | Setup Script Args |
| Unnamed ID | Validate Inputs |
| Unnamed ID | Create Snapshot in Azure App Configuration |
