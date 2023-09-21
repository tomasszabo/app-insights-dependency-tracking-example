using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using Newtonsoft.Json;
using Microsoft.Azure.Cosmos;
using Azure.Storage.Blobs;

namespace simple_app_service.Controllers;

[ApiController]
[Route("[controller]")]
public class GenerateController : ControllerBase
{
	private readonly ILogger<GenerateController> logger;
	private readonly CosmosClient cosmos;
	private readonly BlobContainerClient containerClient;

	public GenerateController(ILogger<GenerateController> logger, 
		CosmosClient cosmos, 
		BlobContainerClient containerClient)
	{
		this.logger = logger;
		this.cosmos = cosmos;
		this.containerClient = containerClient;
	}

	[HttpGet("Message")]
	public async Task<IActionResult> GetMessage()
	{
		Database database = cosmos.GetDatabase("function-test");
		Container container = database.GetContainer("Messages");

		var createdItem = await container.CreateItemAsync(new { 
			message = "hello from new zealand!", 
			id = Guid.NewGuid() 
		});

		return new JsonResult(new
		{
			result = "Message stored"
		});
	}

	[HttpGet("Blob")]
	public async Task<IActionResult> GetBlob()
	{
		await containerClient.CreateIfNotExistsAsync();
		await containerClient.UploadBlobAsync("hello from portugal " + Guid.NewGuid(), new MemoryStream());

		return new JsonResult(new
		{
			result = "Blob stored"
		});
	}
}
