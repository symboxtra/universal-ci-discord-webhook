#!/bin/bash

JENKINS_REPO_SLUG="symboxtra/SplitSound-Android"
OS_NAME="Linux"

if [ -z "$2" ]; then
  echo -e "WARNING!!\nYou need to pass the WEBHOOK_URL environment variable as the second argument to this script.\nFor details & guide, visit: https://github.com/k3rn31p4nic/travis-ci-discord-webhook" && exit
fi

echo -e "[Webhook]: Sending webhook to Discord...\\n";

case $1 in
  "success" )
    EMBED_COLOR=3066993
    STATUS_MESSAGE="Passed"
    AVATAR="https://wiki.jenkins-ci.org/download/attachments/2916393/jenkins-thpr.svg"
    ;;

  "failure" )
    EMBED_COLOR=15158332
    STATUS_MESSAGE="Failed"
    AVATAR="https://wiki.jenkins-ci.org/download/attachments/2916393/fire-jenkins.svg"
    ;;

  * )
    EMBED_COLOR=0
    STATUS_MESSAGE="Status Unknown"
    AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"
    ;;
esac

AUTHOR_NAME="$(git log -1 "${GIT_COMMIT}" --pretty="%aN")"
COMMITTER_NAME="$(git log -1 "${GIT_COMMIT}" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "${GIT_COMMIT}" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "${GIT_COMMIT}" --pretty="%b")"

if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
  CREDITS="$AUTHOR_NAME authored & committed"
else
  CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

#if [[ $TRAVIS_PULL_REQUEST != false ]]; then
#  URL="https://github.com/$TRAVIS_REPO_SLUG/pull/$TRAVIS_PULL_REQUEST"
#else
#  URL=""
#fi
URL="https://github.com/$JENKINS_REPO_SLUG/commit/$GIT_COMMIT"

TIMESTAMP=$(date --utc +%FT%TZ)
WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2",
  "embeds": [ {
    "color": '$EMBED_COLOR',
    "author": {
      "name": "#'"$BUILD_NUMBER"' - '"${JENKINS_REPO_SLUG#*/}"' - '"$OS_NAME"' - '"$STATUS_MESSAGE"'",
      "url": "'"$BUILD_URL"'/console",
      "icon_url": "'$AVATAR'"
    },
    "title": "'"$COMMIT_SUBJECT"'",
    "url": "'"$URL"'",
    "description": "'"${COMMIT_MESSAGE//$'\n'/ }"\\n\\n"$CREDITS"'",
    "fields": [
      {
        "name": "Commit",
        "value": "'"[\`${GIT_COMMIT:0:7}\`](https://github.com/$JENKINS_REPO_SLUG/commit/$GIT_COMMIT)"'",
        "inline": true
      },
      {
        "name": "Branch/Tag",
        "value": "'"[\`${GIT_BRANCH#*/}\`](https://github.com/$JENKINS_REPO_SLUG/tree/${GIT_BRANCH#*/})"'",
        "inline": true
      }
    ],
    "timestamp": "'"$TIMESTAMP"'"
  } ]
}'

(curl -v --fail --progress-bar -A "TravisCI-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "$WEBHOOK_DATA" "$2" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
