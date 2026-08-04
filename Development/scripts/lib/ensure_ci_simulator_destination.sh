#!/usr/bin/env bash
# Library helpers for ensuring CI simulator destinations (#399).
# Stub — deliberately wrong until green implementation.

ensure_ci_sim_pick_runtime_identifier() {
    # Wrong on purpose for deliberate red.
    printf '%s\n' ""
}

ensure_ci_sim_udid_for_name() {
    printf '%s\n' ""
}

ensure_ci_sim_destination_specifier() {
    local platform_family="$1"
    local name="$2"
    local udid="$3"
    printf '%s\n' "platform=${platform_family},name=${name},id=${udid}"
}

ensure_ci_sim_xcode_platform_label() {
    printf '%s\n' "$1"
}

ensure_ci_sim_default_device_type() {
    printf '%s\n' ""
}
