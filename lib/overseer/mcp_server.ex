defmodule Overseer.MCPServer do
  use EMCP.Server,
    name: "overseer-mcp",
    version: "1.0.0",
    tools: Overseer.Tools.read_only(),
    prompts: [],
    resources: [],
    resource_templates: [],
    title: "Overseer MCP",
    description: "MCP server for the Overseer application",
    instructions: "Use the tools to interact with Overseer."
end
