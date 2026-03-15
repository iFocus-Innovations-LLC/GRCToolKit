#!/bin/bash
# Rebase current branch onto origin/main so GitHub can open a PR (fixes "entirely different commit histories")
set -e
BRANCH=$(git branch --show-current)
echo "Branch: $BRANCH"

if [ -n "$(git status --porcelain)" ]; then
  echo "Stashing unstaged changes..."
  git stash push -m "pr-rebase-onto-main"
  STASHED=1
fi

echo "Fetching origin..."
git fetch origin
echo "Rebasing $BRANCH onto origin/main..."
git rebase origin/main

if [ -n "$STASHED" ]; then
  echo "Restoring stashed changes..."
  git stash pop
fi

echo "Done. Now push with:"
echo "  git push origin $BRANCH --force-with-lease"
echo "Then open your PR on GitHub."
