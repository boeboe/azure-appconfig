# Azure App Configuration Set Key-Value

Sets a single key-value pair in Azure App Configuration using Azure CLI.

## Inputs
| Name               | Mandatory | Default         | Description                                    |
|--------------------|-----------|-----------------|------------------------------------------------|
| connectionString | true | None | Connection string for the App Configuration instance. |
| key | true | None | Key to set in Azure App Configuration. |
| value | true | None | Value to associate with the specified key. |
| prefix | false |  | Optional prefix to prepend to the key. |
| label | false | \0 | Optional label to associate with the key-value pair. Defaults to null label. |
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
| Unnamed ID | Set Key-Value in Azure App Configuration |
