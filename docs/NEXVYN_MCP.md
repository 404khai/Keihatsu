# Nexvyn components and MCP

The website registers `@nexvyn` as `https://ui.nexvyn.dev/r/{name}.json` in
`apps/web/components.json`. The official Bounce Sidebar was installed using:

```sh
cd apps/web
npx shadcn@latest add @nexvyn/bounce-sidebar
```

Nexvyn documents the shadcn MCP server as its client integration. The workstation's
Codex configuration now contains `nexvyn`, launching `shadcn mcp` from the
website directory with the working Node 24 runtime. Restart the client to expose
new tools in a fresh session; this existing conversation's tool catalog is not
reloaded by the configuration command. This global machine configuration is not
committed to the project and contains no repository credentials.

For another workstation, configure the shadcn MCP server for your own `apps/web`
path. [Nexvyn MCP setup](https://ui.nexvyn.dev/mcp) and
[Codex MCP setup](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

The docs' right-hand section navigator uses the installed Bounce Sidebar, tracks
scroll position, supports its keyboard controls, and honors reduced-motion settings.
