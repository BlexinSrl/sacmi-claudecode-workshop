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

    [Fact]
    public async Task PutTask_ReplacesExisting()
    {
        var client = NewClient();
        var created = await client.PostAsJsonAsync("/tasks", new { title = "Original" });
        var task = await created.Content.ReadFromJsonAsync<TaskApi.Tasks.TaskItem>();
        Assert.NotNull(task);

        var response = await client.PutAsJsonAsync($"/tasks/{task.Id}", new { title = "Updated", status = "done" });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var replaced = await response.Content.ReadFromJsonAsync<TaskApi.Tasks.TaskItem>();
        Assert.NotNull(replaced);
        Assert.Equal("Updated", replaced.Title);
        Assert.Equal("done", replaced.Status);
    }

    [Fact]
    public async Task PutTask_Returns404_WhenIdNotFound()
    {
        var client = NewClient();
        var response = await client.PutAsJsonAsync("/tasks/999", new { title = "X", status = "todo" });
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteTask_Returns204_WhenExists()
    {
        var client = NewClient();
        var created = await client.PostAsJsonAsync("/tasks", new { title = "ToDelete" });
        var task = await created.Content.ReadFromJsonAsync<TaskApi.Tasks.TaskItem>();
        Assert.NotNull(task);

        var response = await client.DeleteAsync($"/tasks/{task.Id}");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task DeleteTask_Returns404_WhenNotFound()
    {
        var client = NewClient();
        var response = await client.DeleteAsync("/tasks/999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
