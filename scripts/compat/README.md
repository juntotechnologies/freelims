# Compatibility Scripts

This directory contains wrapper scripts for backward compatibility with the previous script structure.

## Overview

The scripts in this directory maintain compatibility with the old script naming and calling conventions. They map the old script names to their equivalents in the new consolidated management system.

## Purpose

These compatibility wrappers serve several purposes:

1. **Smooth Transition**: Allow gradual migration to the new management system
2. **CI/CD Compatibility**: Ensure that any CI/CD pipelines or automated processes continue to work
3. **User Familiarity**: Allow users to continue using commands they are familiar with
4. **Documentation**: Each wrapper includes notes about the equivalent new command to use

## Included Wrappers

- `run_dev_wrapper.sh` - Wrapper for `./run_dev.sh` → `./freelims.sh system dev start`
- `restart_system_wrapper.sh` - Wrapper for `./restart_system.sh` → `./freelims.sh system dev restart`
- `create_admin_wrapper.sh` - Wrapper for `./create_admin_user.sh` → `./freelims.sh user dev create --admin`
- `clear_users_wrapper.sh` - Wrapper for `./clear_users.sh` → `./freelims.sh user dev clear`

## Usage

You should not need to call these scripts directly. Instead:

1. Use the symbolic links in the root directory that point to these wrappers
2. Ideally, migrate to using the new consolidated command syntax

## Deprecation Notice

These compatibility scripts are provided as a temporary measure during the transition to the new management system. They may be deprecated in future releases.

We recommend gradually transitioning to using the new `freelims.sh` command structure as described in the main documentation. 