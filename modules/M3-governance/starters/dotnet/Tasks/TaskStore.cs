namespace TaskApi.Tasks;

public class TaskStore
{
    private readonly List<TaskItem> _tasks = new();
    private int _nextId = 1;

    public IReadOnlyList<TaskItem> All() => _tasks.AsReadOnly();

    public TaskItem Create(string title)
    {
        var task = new TaskItem(_nextId++, title, "todo");
        _tasks.Add(task);
        return task;
    }

    public TaskItem? UpdateStatus(int id, string status)
    {
        var idx = _tasks.FindIndex(t => t.Id == id);
        if (idx < 0) return null;
        var updated = _tasks[idx] with { Status = status };
        _tasks[idx] = updated;
        return updated;
    }

    public TaskItem? Replace(int id, string title, string status)
    {
        var idx = _tasks.FindIndex(t => t.Id == id);
        if (idx < 0) return null;
        var replaced = new TaskItem(id, title, status);
        _tasks[idx] = replaced;
        return replaced;
    }

    public bool Delete(int id)
    {
        var idx = _tasks.FindIndex(t => t.Id == id);
        if (idx < 0) return false;
        _tasks.RemoveAt(idx);
        return true;
    }
}
