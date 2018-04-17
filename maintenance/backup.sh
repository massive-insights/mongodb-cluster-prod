#!/usr/bin/env bash

export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/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
export MONGODB_HOST=localhost
export MONGODB_PORT=37017

echo "Before launching the backup procedure, create a SSH tunnel:"
echo "ssh -L 37017:casper.massive-insights.com:27017 massive@casper.massive-insights.com"

sleep 2

docker run --name mongo-backup \
  -e MONGODB_HOST=$MONGODB_HOST \
  -e MONGODB_PORT=$MONGODB_PORT \
  -e SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL \
  -e SLACK_NOTIFY_ON_FAILURE=true \
  -e SLACK_NOTIFY_ON_WARNING=true \
  --restart=always \
  --add-host="localhost:192.168.3.102" \
  -d kontena/mongo-backup

