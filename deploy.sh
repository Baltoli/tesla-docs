#!/usr/bin/env bash

SITE_DIR=$1

if [ ! -d "$SITE_DIR" ]; then
  echo "Deployment directory: $SITE_DIR does not exist"
  exit 1
fi

if [ ! -d "$SITE_DIR/.git" ]; then
  echo "Deployment directory $SITE_DIR isn't a git repository"
  exit 2
fi

if ! git diff-index --quiet HEAD --; then
  echo "Uncommitted changes - not deploying"
  exit 3
fi

SHA=$(git rev-parse HEAD)

pushd docs
make
popd

mkdocs build -d site
cp -R site/* $SITE_DIR

pushd $SITE_DIR
git add .
git commit -m "Deploy $SHA"
git push -f
popd

rm -rf site
