using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace ServiceBus
{
	public class ReceiveMessage
	{
		[FunctionName("ReceiveMessage")]
		public void Run(
			[ServiceBusTrigger("testqueue", Connection = "ServiceBus")] string message,
			[CosmosDB(databaseName: "function-test",
								containerName: "Messages",
								Connection = "CosmosDB")]out dynamic document,
			ILogger log)
		{
			log.LogInformation($"ReceiveMessage function processed message: {message}");

			document = new { message = message, id = Guid.NewGuid() };
		}
	}
}
