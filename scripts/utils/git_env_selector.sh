#!/bin/bash

# ----------------------------------------------------------------------------
# Git Branch Environment Selector
# This script detects the current git branch and sets environment variables
# accordingly to determine which environment (development or production)
# should be used.
# ----------------------------------------------------------------------------

# Get the current git branch
get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Select environment based on git branch
# Returns 'dev' for develop branch and 'prod' for main/master branch
select_environment() {
  local branch=$(get_current_branch)
  
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "prod"
  else
    echo "dev"
  fi
}

# Determine if the current branch is the production branch
is_production_branch() {
  local branch=$(get_current_branch)
  
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Determine if the current branch is the development branch
is_development_branch() {
  local branch=$(get_current_branch)
  
  if [ "$branch" = "develop" ]; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Usage example
# env=$(select_environment)
# echo "Current environment: $env"
#
# if is_production_branch; then
#   echo "This is the production branch!"
# fi
#
# if is_development_branch; then
#   echo "This is the development branch!"
# fi 