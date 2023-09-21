using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace ServiceBus
{
	public static class GenerateMessage
	{
		[FunctionName("GenerateMessage")]
		public static async Task<IActionResult> Run(
      [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
      [ServiceBus("testqueue", Connection = "ServiceBus")] IAsyncCollector<dynamic> serviceBus,
      ILogger log)
		{
			log.LogInformation($"GenerateMessage function processed a request using method '{req.Method}'.");

			string message = req.Query["message"];

			if (string.IsNullOrEmpty(message)) {
				string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

				if (!string.IsNullOrEmpty(requestBody))
				{
					dynamic data = JsonConvert.DeserializeObject(requestBody);
					message = data.message ?? data.Message;
				}
			}
	
			if (string.IsNullOrEmpty(message))
			{
				message = "Hello World!";
			}

			log.LogInformation("Sending message to queue");

			await serviceBus.AddAsync(message);

			log.LogInformation($"Message '{message}' sent to queue");

			return new OkObjectResult(new
			{
				result = "Message sent"
			});
		}
	}
}
