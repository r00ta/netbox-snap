# Gunicorn configuration for the NetBox snap.
# The bind address is set via --bind on the command line.

import multiprocessing

# Workers: 2 * CPU cores + 1 (capped at a reasonable maximum)
workers = min(2 * multiprocessing.cpu_count() + 1, 9)

# Threads per worker
threads = 3

# Request timeout (seconds)
timeout = 120

# Recycle workers after this many requests to prevent memory leaks
max_requests = 5000
max_requests_jitter = 500

# Access logging to stdout (captured by journald via snap)
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Graceful restart timeout
graceful_timeout = 30
