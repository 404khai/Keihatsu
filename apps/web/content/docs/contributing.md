## Write a page

These docs are Markdown files in `apps/web/content/docs`. Edit an existing page, or add a new `.md` file and register its slug, title and description in `apps/web/lib/docs-index.ts`. Pages are rendered by the website; no CMS account is required.

## Add pictures

Put an image in `apps/web/public/docs/images`. Use a clear filename and describe it in the alt text:

```markdown
![Library with Comfortable grid selected](/docs/images/library-grid.png)
```

The renderer keeps the picture responsive. Use a compressed screenshot and remove private account details before committing it. For a caption, write a normal paragraph below the image.

## Organize headings

Use `##` headings for sections. They automatically appear in the right-hand On this page sidebar. Nexvyn's Bounce Sidebar tracks the current section while you scroll and moves you to a section when clicked. Prefer short, descriptive headings.

## Preview locally

From `apps/web`, install the locked dependencies and run the development server:

```sh
npm ci
npm run dev
```

Open `/docs` on the local website. Check the layout on a narrow screen, keyboard navigation, image alt text and all links before opening a pull request.

## Component registry

The Nexvyn registry is configured in `components.json`. The Bounce Sidebar source is installed under `components/ui`, so it can be maintained alongside the site. The Nexvyn/shadcn MCP setup is documented in `docs/NEXVYN_MCP.md` in the repository.
