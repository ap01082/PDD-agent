FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DISPLAY=:99 \
    RESOLUTION=1280x800

RUN apt-get update && apt-get install -y --no-install-recommends \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 \
    libxcb-xkb1 libegl1 libgl1 libopengl0 libdbus-1-3 \
    libfontconfig1 libfreetype6 libxkbcommon-x11-0 \
    xvfb x11vnc novnc websockify \
    supervisor wget \
    && rm -rf /var/lib/apt/lists/*

RUN pip install uv --no-cache-dir

WORKDIR /app

COPY . .
RUN uv sync

RUN uv run playwright install chromium
RUN uv run playwright install-deps chromium

RUN echo '[supervisord]\nnodaemon=true\nlogfile=/dev/stdout\nlogfile_maxbytes=0\nuser=root\n\n[program:xvfb]\ncommand=Xvfb :99 -screen 0 1280x800x24 -ac\npriority=1\nautostart=true\nautorestart=true\nstdout_logfile=/dev/stdout\nstderr_logfile=/dev/stdout\n\n[program:x11vnc]\ncommand=x11vnc -display :99 -forever -shared -nopw -quiet\npriority=2\nautostart=true\nautorestart=true\nstdout_logfile=/dev/stdout\nstderr_logfile=/dev/stdout\n\n[program:novnc]\ncommand=websockify --web /usr/share/novnc 6080 localhost:5900\npriority=3\nautostart=true\nautorestart=true\nstdout_logfile=/dev/stdout\nstderr_logfile=/dev/stdout\n\n[program:app]\ncommand=/app/.venv/bin/python app.py\npriority=4\nautostart=true\nautorestart=true\nstdout_logfile=/dev/stdout\nstderr_logfile=/dev/stdout\n' > /etc/supervisor/conf.d/app.conf

EXPOSE 6080

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]