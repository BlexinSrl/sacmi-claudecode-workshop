using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

public class TasksEndpointsTests
{
    private static HttpClient NewClient() => new WebApplicationFactory<Program>().CreateClient();

    [Fact]
    public async Task GetTasks_ReturnsEmptyList_Initially()
    {
        var client = NewClient();
        var response = await client.GetAsync("/tasks");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var tasks = await response.Content.ReadFromJsonAsync<List<TaskApi.Tasks.TaskItem>>();
        Assert.NotNull(tasks);
        Assert.Empty(tasks);
    }

    [Fact]
    public async Task PostTask_CreatesTask_WithTodoStatus()
    {
        var client = NewClient();
        var response = await client.PostAsJsonAsync("/tasks", new { title = "Test" });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<TaskApi.Tasks.TaskItem>();
        Assert.NotNull(created);
        Assert.Equal("Test", created.Title);
        Assert.Equal("todo", created.Status);
    }
}
