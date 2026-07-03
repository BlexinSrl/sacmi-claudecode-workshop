import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { tasksRoutes } from "./tasks/routes.js";

export function createApp(): Hono {
  const app = new Hono();
  app.route("/", tasksRoutes());
  return app;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const app = createApp();
  const port = Number(process.env.PORT ?? 3000);
  serve({ fetch: app.fetch, port });
  console.log(`Listening on http://localhost:${port}`);
}
