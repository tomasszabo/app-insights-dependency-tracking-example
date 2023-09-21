# App Insights dependency tracking example

This repository contains example of App Insights dependency tracking using App Insights SDK and auto instrumentation.

# Architecture

Architecture consist of:

- ServiceBus
- Azure Function to produce messages and write them to ServiceBus queue
- Azure Function to receive messages from ServiceBus queue
- CosmosDB Database to store received messages
- App Service with 

# Deployment

To deploy required Azure Resources, go to `bicep` directory and execute following Azure CLI command:

```bash
az deployment group create \
    --resource-group {{resourceGroupName}} \
    --name {{deploymentName}} \
    --template-file main.bicep \
    --parameters sqlPassword={{yourPassword}}
```

After Azure resources were provisioned, both Azure Functions and App Services needs to be deployed for example from Visual Studio Code - [deploy Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=node-v3%2Cpython-v2%2Cin-process&pivots=programming-language-csharp#publish-to-azure) and [deploy App Service](https://learn.microsoft.com/en-us/aspnet/core/tutorials/publish-to-azure-webapp-using-vscode?view=aspnetcore-7.0#publish-to-azure-app-service).

# Generate Message

After successful deployment go to `Azure Portal > functionapp > GenerateMessage` and copy `Function Url` to clipboard. Open deployed Web App in browser and paste this function url to nput field and select `Call API`. 

After successful execution, message is sent to ServiceBus queue.

# Receive Message

After message was generated, second Azure Function is listening for messages in ServiceBus queue. After a message was received, it is inserted as a new record into CosmosDB Database.

# Dependencies in App Insights

After message was generated and received, go to `Azure Portal > appinsights > Transaction Search` and refresh data. It may take up to couple of minutes until the data are visible in App Insights. Look for `Dependency` logs. If you open one dependency log, you'll should see the whole end to end transaction:

`Web App` -> `Function 1` -> `Service Bus` -> `Function 2` -> `Cosmos DB`

# License

Distributed under MIT License. See [LICENSE](LICENSE) for more details.