# ============================================================================
# Claude Code OpenTelemetry Configuration
# ============================================================================

# Enable telemetry
export CLAUDE_CODE_ENABLE_TELEMETRY=0
# export CLAUDE_CODE_ENABLE_TELEMETRY=1

# ============================================================================
# EXPORTER CONFIGURATION
# ============================================================================

# File-based logging via OTLP (writes to ~/.claude/telemetry/)
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/json
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Alternative: Console mode (uncomment to use - prints to terminal)
# export OTEL_METRICS_EXPORTER=console
# export OTEL_LOGS_EXPORTER=console

# ============================================================================
# EXPORT INTERVALS
# ============================================================================

# How often to batch and export telemetry data
export OTEL_METRIC_EXPORT_INTERVAL=60000  # Metrics every 60 seconds
export OTEL_LOGS_EXPORT_INTERVAL=5000     # Logs every 5 seconds

# ============================================================================
# ATTRIBUTES & METADATA
# ============================================================================

# Include these attributes in all metrics
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true
export OTEL_METRICS_INCLUDE_VERSION=false

# Custom resource attributes (for filtering/grouping your data)
export OTEL_RESOURCE_ATTRIBUTES="environment=personal,purpose=config-optimization"

# ============================================================================
# PRIVACY SETTINGS
# ============================================================================

# By default, user prompts are redacted (only length is logged)
# Uncomment to log full prompt text (NOT recommended):
# export OTEL_LOG_USER_PROMPTS=1

# ============================================================================
# WHAT'S BEING TRACKED
# ============================================================================
# Metrics:
#   - claude_code.session.count (sessions started)
#   - claude_code.token.usage (tokens consumed)
#   - claude_code.cost.usage (USD cost)
#   - claude_code.lines_of_code.count (code modified)
#   - claude_code.commit.count (git commits)
#   - claude_code.pull_request.count (PRs created)
#   - claude_code.code_edit_tool.decision (tool permissions)
#   - claude_code.active_time.total (usage time)
#
# Events/Logs:
#   - claude_code.user_prompt (submissions, redacted by default)
#   - claude_code.tool_result (tool execution completion)
#   - claude_code.api_request (API calls)
#   - claude_code.api_error (failures)
#   - claude_code.tool_decision (accept/reject)
# ============================================================================

