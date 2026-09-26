# fasveltekitapi

uv + fastapi + pnpm + sveltekit + git repo auto create script

## what it does

this script scaffolds a full-stack project in one go:

- initializes a git repository
- creates a `backend/` folder with `uv`, installs `fastapi[standard]`, and writes a minimal `main.py` with cors enabled for `localhost` and `localhost:5173`
- creates a `frontend/` folder with `sveltekit` (minimal template, no typescript, prettier + eslint, pnpm) and writes a `+page.svelte` that fetches from the backend and displays the result
- commits the initial scaffold
- starts both dev servers (`fastapi dev` and `pnpm dev`) in the background

## requirements

- [uv](https://docs.astral.sh/uv/)
- [pnpm](https://pnpm.io/)
- git

## usage

```bash
chmod +x setup.sh
./setup.sh
```

this will:

1. create the backend and frontend projects
2. commit everything as `init`
3. run the backend at `http://localhost:8000`
4. run the frontend at `http://localhost:5173`

press `ctrl + c` to stop both servers.

## project structure

```
.
├── backend/
│   ├── main.py
│   └── .gitignore
└── frontend/
    └── src/
        └── routes/
            └── +page.svelte
```

## notes

- the backend exposes a single `GET /` route returning `{"message": "Hello World"}`
- the frontend fetches that message on mount and renders it in an `<h1>`
- cors is preconfigured for local sveltekit dev (`localhost:5173`)
- this readme was written by ai
- the script source code was not — i wrote it myself