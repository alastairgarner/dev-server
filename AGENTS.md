# Shared development infrastructure

This stack is managed by the machine owner, not individual application agents.
Applications should use the existing MongoDB and Redis endpoints on localhost.
Use separate database names / Redis namespaces for isolated development work.

Do not start replacement containers, restart shared services, change limits, or
delete volumes unless explicitly asked. These services may be used by other agents.
Never run two MongoDB instances against the same data volume.
Keep machine-specific volume mappings in ignored .env, not compose.yaml.
