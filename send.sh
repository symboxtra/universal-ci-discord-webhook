#!/bin/bash
# Author: Symboxtra Software
# License: MIT

WEBHOOK_VERSION="2.0.0.0"

STATUS="$1"
WEBHOOK_URL="$2"
CURRENT_TIME=`date +%s`

unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
    OS_NAME="OSX"
else
    OS_NAME="Linux"
fi

if [ -z "$STATUS" ]; then
    echo -e "WARNING!!"
    echo -e "You need to pass the WEBHOOK_URL environment variable as the second argument to this script."
    echo -e "For details & guide, visit: https://github.com/symboxtra/jenkins-discord-webhook"
    exit
fi

echo -e "[Webhook]: Sending webhook to Discord..."

case $1 in
  "success" )
    EMBED_COLOR=3066993
    STATUS_MESSAGE="Passed"
    AVATAR="https://jenkins.io/images/logos/cute/cute.png"
    ;;
  "failure" )
    EMBED_COLOR=15158332
    STATUS_MESSAGE="Failed"
    AVATAR="https://jenkins.io/images/logos/fire/fire.png"
    ;;
  * )
    EMBED_COLOR=0
    STATUS_MESSAGE="Status Unknown"
    AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"
    ;;
esac

if [ -z "$GIT_COMMIT" ]; then
    GIT_COMMIT="$(git log -1 --pretty="%H")"
fi

AUTHOR_NAME="$(git log -1 "${GIT_COMMIT}" --pretty="%aN")"
COMMITTER_NAME="$(git log -1 "${GIT_COMMIT}" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "${GIT_COMMIT}" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "${GIT_COMMIT}" --pretty="%b")"
COMMIT_TIME="$(git log -1 "${GIT_COMMIT}" --pretty="%ct")"

GIT_URL=$(git config --get remote.origin.url)
JENKINS_REPO_SLUG=${GIT_URL#*"github.com/"}
JENKINS_REPO_SLUG=${JENKINS_REPO_SLUG%".git"*}

if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
  CREDITS="$AUTHOR_NAME authored & committed"
else
  CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

# Calculate approximate build time based on commit
DISPLAY_TIME=$(date -u -d "0 $CURRENT_TIME seconds - $COMMIT_TIME seconds" +"%M:%S")



# Regex match co-author names
if [[ "$COMMIT_MESSAGE" =~ Co-authored-by: ]]; then
    IFS=$'\n'
    CO_AUTHORS=($(echo "$COMMIT_MESSAGE" | grep -o "\([A-Za-z]\+ \)\+[A-Za-z]\+"))

    if [ ${#CO_AUTHORS[@]} -gt 0 ]; then
        IFS=","
        CO_AUTHORS="${CO_AUTHORS[*]}"
        CO_AUTHORS="${CO_AUTHORS//,/, }"
    fi
    unset IFS
else
    CO_AUTHORS="None"
fi

# Replace git hashes in merge commits
IFS=$'\n'
MATCHES=($(echo "$COMMIT_SUBJECT" | grep -o "Merge \w\{40\}\b into \w\{40\}\b"))
if [ "${#MATCHES[@]}" -gt 0 ]; then
    IS_PR=true
    MATCHES=($(echo "$COMMIT_SUBJECT" | grep -o "\w\{40\}\b"))
    for MATCH in "${MATCHES[@]}"
    do
        HASH="$MATCH"
        BRANCH_NAME="$(git name-rev $HASH --name-only)"
        COMMIT_SUBJECT="${COMMIT_SUBJECT//$HASH/${BRANCH_NAME:-$HASH}}"
    done
fi
unset IFS

# Remove repo owner: symboxtra/project -> project
REPO_NAME=${JENKINS_REPO_SLUG#*/}

#Create appropriate link (we don't have the PR number in Jenkins)
if [[ -n "$IS_PR" ]]; then
    URL="https://github.com/$JENKINS_REPO_SLUG/pulls"
else
    URL="https://github.com/$JENKINS_REPO_SLUG/commit/$GIT_COMMIT"
fi


TIMESTAMP=$(date --utc +%FT%TZ)
WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "'$AVATAR'",
  "embeds": [ {
    "color": '$EMBED_COLOR',
    "author": {
      "name": "#'"$BUILD_NUMBER"' - '"$REPO_NAME"' - '"$STATUS_MESSAGE"'",
      "url": "'"$BUILD_URL"'/console",
      "icon_url": "'$AVATAR'"
    },
    "title": "'"$COMMIT_SUBJECT"'",
    "url": "'"$URL"'",
    "description": "'"${COMMIT_MESSAGE}"\\n\\n"$CREDITS"'",
    "fields": [
      {
        "name": "OS",
        "value": "'"$OS_NAME"'",
        "inline": true
      },
      {
        "name": "Build Time",
        "value": "'"~$DISPLAY_TIME"'",
        "inline": true
      },
      {
        "name": "Build ID",
        "value": "'"${BUILD_NUMBER}CI"'",
        "inline": true
      },
      {
        "name": "Commit",
        "value": "'"[\`${GIT_COMMIT:0:7}\`](https://github.com/$JENKINS_REPO_SLUG/commit/$GIT_COMMIT)"'",
        "inline": true
      },
      {
        "name": "Branch/Tag",
        "value": "'"[\`${GIT_BRANCH#*/}\`](https://github.com/$JENKINS_REPO_SLUG/tree/${GIT_BRANCH#*/})"'",
        "inline": true
      },
      {
        "name": "Co-Authors",
        "value": "'"$CO_AUTHORS"'",
        "inline": true
      }
    ],
    "footer": {
        "text": "'"v$WEBHOOK_VERSION"'"
      },
    "timestamp": "'"$TIMESTAMP"'"
  } ]
}'



(curl -v --fail --progress-bar -A "Jenkins-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "$WEBHOOK_DATA" "$WEBHOOK_URL" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."

if false ; then
    echo "This code"
fi
if false ; then
    echo "should make"
fi
if false ; then
    echo "the coverage 50/50."
fi
if false ; then
    echo "JK we needed one more"
fi
true || echo "Balanced?"
