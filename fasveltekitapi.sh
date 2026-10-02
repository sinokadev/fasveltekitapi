#!/bin/bash

set -e

MODE="full"

while [ $# -gt 0 ]; do
    case "$1" in
        --backend-only|-b)
            if [ "$MODE" != "full" ]; then
                echo "error: backend-only and frontend-only cannot be used together"
                exit 1
            fi
            MODE="backend"
            ;;
        --frontend-only|-f)
            if [ "$MODE" != "full" ]; then
                echo "error: backend-only and frontend-only cannot be used together"
                exit 1
            fi
            MODE="frontend"
            ;;
        --help|-h)
            echo "Usage:"
            echo "  curl -sL sinoka.dev/fasveltekitapi.sh | bash"
            echo "  curl -sL sinoka.dev/fasveltekitapi.sh | bash -s -- --backend-only"
            echo "  curl -sL sinoka.dev/fasveltekitapi.sh | bash -s -- --frontend-only"
            echo
            echo "Options:"
            echo "  -b, --backend-only   Create backend only in current directory"
            echo "  -f, --frontend-only  Create frontend only in current directory"
            echo "  -h, --help           Show this help"
            exit 0
            ;;
        *)
            echo "unknown option: $1"
            exit 1
            ;;
    esac

    shift
done


echo "making project in this directory"

git init


create_backend() {
    local target="$1"

    if [ "$target" = "." ]; then
        uv init
    else
        uv init "$target"
    fi

    (
        cd "$target"

        uv add 'fastapi[standard]'

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

        cat <<'EOF' >> .gitignore
.venv
.venv/**
__pycache__
__pycache__/**
EOF
    )
}


create_frontend() {
    local target="$1"

    if [ "$target" = "." ]; then
        pnpm dlx sv create . \
            --template minimal \
            --no-types \
            --add prettier eslint \
            --install pnpm \
            --no-dir-check
    else
        pnpm dlx sv create "$target" \
            --template minimal \
            --no-types \
            --add prettier eslint \
            --install pnpm
    fi

    cat <<'EOF' > "$target/src/routes/+page.svelte"
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
}


case "$MODE" in
    full)
        echo "creating backend..."
        create_backend "backend"

        echo "creating frontend..."
        create_frontend "frontend"
        ;;

    backend)
        echo "creating backend in current directory..."
        create_backend "."
        ;;

    frontend)
        echo "creating frontend in current directory..."
        create_frontend "."
        ;;
esac


git add .
git commit -m "init"


cleanup() {
    local pids
    pids="$(jobs -pr)"

    if [ -n "$pids" ]; then
        kill $pids 2>/dev/null || true
    fi
}

trap cleanup EXIT


case "$MODE" in
    full)
        (cd backend && uv run fastapi dev) &
        (cd frontend && pnpm dev) &
        ;;

    backend)
        uv run fastapi dev &
        ;;

    frontend)
        pnpm dev &
        ;;
esac


echo
echo "ctrl + c to stop server"

wait
