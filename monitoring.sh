#!/usr/bin/bash

set -eux

post_to_slack () {
  target_host=$1
  ip_version=$2
  check_type=$3
  is_recovered=$4
  state_message="失われ"
  if [[ $is_recovered -eq 1 ]]; then
    state_message="復旧し"
  fi

  echo "$target_hostへのIPv${ip_version},${check_type}疎通が${state_message}ました"|/usr/local/bin/slackcat -s -i ':exclamation:' -u '疎通監視くん' --channel monitoring --token $SLACKCAT_TOKEN
}

lost_file_name () {
  target_host=$1
  ip_version=$2
  check_type=$3

  echo "${target_host}_ipv${ip_version}_${check_type}.lost"
}

mark_failed () {
  target_host=$1
  ip_version=$2
  check_type=$3

  touch `lost_file_name $target_host $ip_version $check_type`
}

mark_recovered () {
  target_host=$1
  ip_version=$2
  check_type=$3

  rm `lost_file_name $target_host $ip_version $check_type`
}

failed () {
  target_host=$1
  ip_version=$2
  check_type=$3

  post_to_slack $target_host $ip_version $check_type 0
  mark_failed $target_host $ip_version $check_type
}

recovered () {
  target_host=$1
  ip_version=$2
  check_type=$3

  post_to_slack $target_host $ip_version $check_type 1
  mark_recovered $target_host $ip_version $check_type
}

ping_test () {
  target_host=$1
  ip_version=$2
  ping_count=$3
  check_type="ping"
  loss_rate=$(ping -${ip_version}qc ${ping_count} ${target_host} | sed -n '4p' | sed -E 's/.*, ([0-9]+([.][0-9]*)?)% packet loss,.*/\1/')
  if [[ $loss_rate -gt 5 ]]; then
    failed $target_host $ip_version $check_type
  else
    if [ -e `lost_file_name $target_host $ip_version $check_type` ]; then
      recovered $target_host $ip_version $check_type
    fi
  fi
}

https_test () {
  target_host=$1
  ip_version=$2
  check_type="https"

  response_code=`curl -s${ip_version}L https://${TARGET_HOST}/ -o /dev/null -w '%{http_code}\n'`
  if [[ $response_code -ne 200 ]]; then
    failed $target_host $ip_version $check_type
  else
    if [ -e `lost_file_name $target_host $ip_version $check_type` ]; then
      recovered $target_host $ip_version $check_type
    fi
  fi
}



ping_count=10
ip_version=4

ping_test $TARGET_HOST $ip_version $ping_count

if [[ $MONITOR_V6 -eq 1 ]]; then
  ip_version=6
  ping_test $TARGET_HOST $ip_version $ping_count
fi

if [[ $MONITOR_V4_HTTPS -eq 1 ]]; then
  ip_version=4
  https_test $TARGET_HOST $ip_version
fi

if [[ $MONITOR_V6_HTTPS -eq 1 ]]; then
  ip_version=6
  https_test $TARGET_HOST $ip_version
fi

