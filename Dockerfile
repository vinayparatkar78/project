# Stage 1: Build
FROM python:3.10-slim-bullseye AS build

ENV PYTHONUNBUFFERED 1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python packages in a separate directory
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.10-slim-bullseye AS runtime

ENV PYTHONUNBUFFERED 1

# Install only runtime dependencies if needed (optional)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/

# Copy app files
COPY . .

# Copy installed Python packages from build stage
COPY --from=build /root/.local /root/.local

# Make sure PATH can find the installed packages
ENV PATH=/root/.local/bin:$PATH

RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]

