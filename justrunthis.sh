#!/bin/bash

set -e

echo "making project this directory"

git init

uv init backend
cd backend
uv add fastapi[standard]

cat <<'EOF' > main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

origins = [
    "http://localhost",
    "http://localhost:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def main():
    return {"message": "Hello World"}
EOF

cat <<'EOF' > .gitignore
.venv
.venv/**
__pycache__
__pycache__/**
EOF

cd ..

pnpx sv create frontend --template minimal --no-types --add prettier eslint --install pnpm


cd frontend/src/routes

cat <<'EOF' > +page.svelte
<script>
    import { onMount } from 'svelte';

    let result = $state('loading');

    async function getData() {
        const url = "http://localhost:8000/";
        try {
            const response = await fetch(url);
            const data = await response.json();
            result = data.message;
        } catch (error) {
            console.error(error);
            result = 'error!';
        }
    }

    onMount(() => {
        getData();
    });
</script>

<h1>{result}</h1>
EOF

cd ../../..

git add .

git commit -m "init"

(cd backend && uv run fastapi dev) &

(cd frontend && pnpm dev) &

trap 'kill $(jobs -p)' EXIT

echo "ctrl + c to stop server"

wait