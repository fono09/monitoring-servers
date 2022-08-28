#!/usr/bin/bash

set -eux

if ! ping -c 5 -4 $TARGET_HOST > /dev/null; then
  echo "$TARGET_HOSTへのIPv4,ping疎通が失われました"|/usr/local/bin/slackcat -s --channel monitoring --token $SLACKCAT_TOKEN
fi

if ! ping -c 5 -6 $TARGET_HOST > /dev/null; then
  echo " $TARGET_HOSTへのIPv6,ping疎通が失われました"|/usr/local/bin/slackcat -s --channel monitoring --token $SLACKCAT_TOKEN
fi

if [[ $MONITOR_V4_HTTPS -eq 1 ]]; then
  response_code=`curl -4sL https://{$TARGET_HOST}/ -o /dev/null -w '%{http_code}\n'`
  if [[ "$response_code" -ne 200 ]]; then
    echo "$TARGET_HOSTへのIPv4,https疎通が失われました" |/usr/local/bin/slackcat -s --channel monitoring --token $SLACKCAT_TOKEN
  fi
fi

if [[ $MONITOR_V6_HTTPS -eq 1 ]]; then
  response_code=`curl -6sL https://{$TARGET_HOST}/ -o /dev/null -w '%{http_code}\n'`
  if [[ $response_code -ne 200 ]]; then
    echo "$TARGET_HOSTへのIPv6,https疎通が失われました" |/usr/local/bin/slackcat -s --channel monitoring --token $SLACKCAT_TOKEN
  fi
fi

