FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1

WORKDIR /app

COPY tests/mock-producer/requirements.txt ./requirements.txt
RUN uv pip install --system -r requirements.txt

COPY tests/mock-producer/src ./src
COPY tests/json_schemas /json_schemas

CMD ["python", "-m", "src.main"]
