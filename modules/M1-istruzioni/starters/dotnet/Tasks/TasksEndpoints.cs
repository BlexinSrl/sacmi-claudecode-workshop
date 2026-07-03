namespace TaskApi.Tasks;

public static class TasksEndpoints
{
    public static void MapTasks(this WebApplication app)
    {
        app.MapGet("/tasks", (TaskStore store) => Results.Ok(store.All()));

        app.MapPost("/tasks", (CreateTaskRequest req, TaskStore store) =>
        {
            if (string.IsNullOrWhiteSpace(req.Title))
                return Results.BadRequest(new { error = "title required" });
            var created = store.Create(req.Title);
            return Results.Created($"/tasks/{created.Id}", created);
        });

        app.MapPatch("/tasks/{id:int}", (int id, UpdateStatusRequest req, TaskStore store) =>
        {
            if (req.Status != "todo" && req.Status != "done")
                return Results.BadRequest(new { error = "status must be 'todo' or 'done'" });
            var updated = store.UpdateStatus(id, req.Status);
            return updated is null ? Results.NotFound() : Results.Ok(updated);
        });
    }

    public record CreateTaskRequest(string Title);
    public record UpdateStatusRequest(string Status);
}
