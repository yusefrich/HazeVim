# 5. Express route graph and reachability

- Status: Accepted
- Date: 2026-11-22

## Context

An Express route can have more than one handler (`router.get(path, auth, load, respond)`), and middleware can call upstream services. A router can be made by a factory and stored in a variable before it is mounted. The call graph can have cycles.

## Decision

- Each middleware and handler of a route is a node. If a route has more than one handler, a synthetic route node has an edge to each handler.
- A mounted router variable has two router keys: the variable and the factory function that made it. A mount prefix applies to routes that match either key.
- Reach is a BFS for each node. There is no shared memo, because a memo filled inside a cycle is not complete.

## Consequences

- Upstream calls in middleware show on the route.
- Reach costs more on very large graphs. Measured cost is small for typical BFFs.
