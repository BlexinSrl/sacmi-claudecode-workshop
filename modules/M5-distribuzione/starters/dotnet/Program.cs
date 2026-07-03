using TaskApi.Tasks;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<TaskStore>();
var app = builder.Build();
app.MapTasks();
app.Run();

public partial class Program { }
