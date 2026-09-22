# Retrospective

Accident narratives belong here. Keep only recurring project rules in `AGENTS.md`; cross-project lessons belong in global rules and deterministic checks in hooks/tests.

## Undated migrated accessibility validation incident

This accessibility increment passed scripts/check.sh (58 tests, examples and
Release), the Debug build, and the added identifier/control-style assertions in
both native attempts. The complete native runs were 56/57 and 55/57: foreground
loss invalidated a drag in each, and the second also had one ScreenCaptureKit
capture failure. Frames remained fixed and drag previews/commits were correct.
Keep both failed reports under .local/warp-surface/sdk-accessibility-native-{1,2};
do not describe those complete runs as passed. No drag or geometry code changed
in this increment; consumer-mounted dragging is validated separately.
