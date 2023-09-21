using Microsoft.Azure.Cosmos;
using Azure.Storage.Blobs;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

ConfigurationManager configuration = builder.Configuration;

builder.Services.AddSingleton<CosmosClient>((serviceProvider) =>
{
  return new CosmosClient(configuration.GetConnectionString("CosmosDB"));
});

builder.Services.AddSingleton<BlobContainerClient>((serviceProvider) =>
{
  return new BlobContainerClient(configuration.GetConnectionString("BlobStorage"), "messages");
});

builder.Services.AddCors(options =>
{
  options.AddPolicy("AllowAll",
    cors =>
    {
      cors
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowAnyOrigin();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
  app.UseSwagger();
  app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
