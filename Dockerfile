FROM python:3.9-slim

WORKDIR /app

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser -u 1000 appuser

# Copy and install dependencies first (for better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    chown -R appuser:appuser /app

# Copy application code
COPY --chown=appuser:appuser app.py .

# Switch to non-root user
USER appuser

EXPOSE 8080

# Use gunicorn for production (better than Flask dev server)
# Use Flask dev server for local development: CMD ["python", "app.py"]
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", "--timeout", "120", "app:app"]