# 1. Official Python image, same version as .python-version, small "slim" variant
FROM python:3.13-slim

# 2. Standard OCI labels describing the image
LABEL org.opencontainers.image.title="book-analysis" \
      org.opencontainers.image.description="Lab 09: Lab 07 book analysis (S3 books -> MongoDB Atlas) packaged as a container image" \
      org.opencontainers.image.source="https://github.com/Dzau/lab-09-containers"

# 3. The uv program, in a fixed version, copied from the official uv image
COPY --from=ghcr.io/astral-sh/uv:0.12.18 /uv /bin/uv

# 4. An ordinary (non-root) user to run the container
RUN useradd --create-home app

# 5. Working directory for everything below
WORKDIR /app

# 6. Only the dependency files first, so code changes don't reinstall packages
COPY pyproject.toml uv.lock ./

# 7. Install exactly the locked packages into /app/.venv (not the project itself)
RUN uv sync --frozen --no-dev --no-install-project --no-cache

# 8. The code, after the install
COPY src/ ./src/

# 9. Use the venv's python first, and let Python find the book_analysis package
ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONPATH=/app/src

# 10. Run as the ordinary user, not root
USER app

# 11. Run the analysis when the container starts
ENTRYPOINT ["python", "-m", "book_analysis.analyze"]

# 12. Default argument: show the help; arguments after the image name replace it
CMD ["--help"]
