#!/bin/bash
# Author: Symboxtra Software
# Author of travis-ci-discord Webhook and appveyor-discord-webhook:
#    Sankarsan Kampa (a.k.a. k3rn31p4nic)
# License: MIT

WEBHOOK_VERSION="2.0.0.0"

unamestr=`uname`
if [ "${unamestr}" = 'Darwin' ]; then
    OS_NAME="OSX"
else
    OS_NAME="Linux"
fi

STATUS="$1"
WEBHOOK_URL="$2"
CURRENT_TIME=`date +%s`

STRICT_MODE=false
if [ "$3" = "strict" ]; then
    STRICT_MODE=true
fi

if [ "${WEBHOOK_URL}" = "" ]; then
    echo -e "WARNING!"
    echo -e "You need to pass the WEBHOOK_URL environment variable as the second argument to this script."
    echo -e "For details & guidance, visit: https://github.com/symboxtra/universal-ci-discord-webhook"

    if [ "${STRICT_MODE}" = "true" ]; then
        exit 1
    else
        exit 0
    fi
fi

# The following variables must be defined for each CI service:
# CI_PROVIDER=""      # Name of CI provider
# DISCORD_AVATAR=""   # Large avatar for Discord user icon
# SUCCESS_AVATAR=""   # Avatar for successful build
# FAILURE_AVATAR=""   # Avatar for failed build
# UNKNOWN_AVATAR=""   # Avatar for unknown build
# BRANCH_NAME=""      # Branch name
# COMMIT_HASH=""      # Hash of current commit
# PULL_REQUEST_ID=""  # Id of PR if present
# REPO_SLUG=""        # "owner/project" format for GitHub
# BUILD_NUMBER=""     # Identifier for build
# BUILD_URL=""        # Link to the build page

# These conditions come from the codecov bash script
# Apache License Version 2.0, January 2004
# https://github.com/codecov/codecov-bash/blob/master/LICENSE
if [ "${CI}" = "true" ] && [ "${TRAVIS}" = "true" ] && [ "${SHIPPABLE}" != "true" ];
then

    CI_PROVIDER="Travis"
    DISCORD_AVATAR="https://travis-ci.org/images/logos/TravisCI-Mascot-1.png"
    SUCCESS_AVATAR="https://travis-ci.org/images/logos/TravisCI-Mascot-blue.png"
    FAILURE_AVATAR="https://travis-ci.org/images/logos/TravisCI-Mascot-red.png"
    UNKNOWN_AVATAR="https://travis-ci.org/images/logos/TravisCI-Mascot-1.png"

    BRANCH_NAME="${TRAVIS_BRANCH}"
    COMMIT_HASH="${TRAVIS_PULL_REQUEST_SHA:-$TRAVIS_COMMIT}"
    PULL_REQUEST_ID="${TRAVIS_PULL_REQUEST}"
    REPO_SLUG="${TRAVIS_REPO_SLUG}"
    BUILD_NUMBER="${TRAVIS_BUILD_NUMBER}"
    if [ "${TRAVIS_JOB_NUMBER}" != "" ]; then
        BUILD_NUMBER="${TRAVIS_JOB_NUMBER}"
    fi

    BUILD_URL="https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}"

elif [ "${JENKINS_URL}" != "" ];
then

    CI_PROVIDER="Jenkins"
    DISCORD_AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"
    SUCCESS_AVATAR="https://jenkins.io/images/logos/cute/cute.png"
    FAILURE_AVATAR="https://jenkins.io/images/logos/fire/fire.png"
    UNKNOWN_AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"

    # BRANCH_NAME
    if [ "${ghprbSourceBranch}" != "" ];
    then
        BRANCH_NAME="${ghprbSourceBranch}"
    elif [ "${GIT_BRANCH}" != "" ];
    then
        BRANCH_NAME="${GIT_BRANCH}"
    elif [ "${BRANCH_NAME}" != "" ];
    then
        BRANCH_NAME="${BRANCH_NAME}"
    fi

    # COMMIT_HASH
    if [ "${ghprbActualCommit}" != "" ];
    then
        COMMIT_HASH="${ghprbActualCommit}"
    elif [ "${GIT_COMMIT}" != "" ];
    then
        COMMIT_HASH="${GIT_COMMIT}"
    fi

    # PULL_REQUEST_ID
    if [ "${ghprbPullId}" != "" ];
    then
        PULL_REQUEST_ID="${ghprbPullId}"
    elif [ "${CHANGE_ID}" != "" ];
    then
        PULL_REQUEST_ID="${CHANGE_ID}"
    fi

    REPO_URL="$(git remote get-url origin)"
    REPO_SLUG="$(echo ${REPO_URL} | sed -e 's/.*github.com\///g' -e 's/\.git.*//g')"

    BUILD_NUMBER="${BUILD_NUMBER}"
    BUILD_URL="${BUILD_URL}/console"

else

    echo "No CI service detected. Service not found or not supported? Open an issue on GitHub!"

    if [ "${STRICT_MODE}" = "true" ]; then
        exit 1
    else
        exit 0
    fi

fi

# Check that all variables were found
ALL_FOUND=true

if [ "${CI_PROVIDER}" = "" ]; then
    echo "CI_PROVIDER not defined."
    ALL_FOUND=false
fi
if [ "${DISCORD_AVATAR}" = "" ]; then
    echo "DISCORD_AVATAR not defined."
    ALL_FOUND=false
fi
if [ "${SUCCESS_AVATAR}" = "" ]; then
    echo "SUCCESS_AVATAR not defined."
    ALL_FOUND=false
fi
if [ "${FAILURE_AVATAR}" = "" ]; then
    echo "FAILURE_AVATAR not defined."
    ALL_FOUND=false
fi
if [ "${UNKNOWN_AVATAR}" = "" ]; then
    echo "UNKNOWN_AVATAR not defined."
    ALL_FOUND=false
fi
if [ "${BRANCH_NAME}" = "" ]; then
    echo "BRANCH_NAME not defined."
    ALL_FOUND=false
fi
if [ "${COMMIT_HASH}" = "" ]; then
    echo "COMMIT_HASH not defined."
    ALL_FOUND=false
fi
if [ "${REPO_SLUG}" = "" ]; then
    echo "REPO_SLUG not defined."
    ALL_FOUND=false
fi
if [ "${BUILD_NUMBER}" = "" ]; then
    echo "BUILD_NUMBER not defined."
    ALL_FOUND=false
fi
if [ "${BUILD_URL}" = "" ]; then
    echo "BUILD_URL not defined."
    ALL_FOUND=false
fi

if [ "${STRICT_MODE}" = "true" ] && [ "${ALL_FOUND}" = "false" ]; then
    echo "[Webhook]: CI detection failed. Strict mode was enabled and one or more variables was undefined."
    exit 1
fi

echo
echo -e "[Webhook]: ${CI_PROVIDER} CI detected."
echo -e "[Webhook]: Sending webhook to Discord..."
echo

case $1 in
  "success" )
    EMBED_COLOR=3066993
    STATUS_MESSAGE="Passed"
    AVATAR="${SUCCESS_AVATAR}"
    ;;
  "failure" )
    EMBED_COLOR=15158332
    STATUS_MESSAGE="Failed"
    AVATAR="${FAILURE_AVATAR}"
    ;;
  * )
    EMBED_COLOR=8421504
    STATUS_MESSAGE="Unknown"
    AVATAR="${UNKNOWN_AVATAR}"
    ;;
esac

AUTHOR_NAME="$(git log -1 ${COMMIT_HASH} --pretty="%aN")"
COMMITTER_NAME="$(git log -1 ${COMMIT_HASH} --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 ${COMMIT_HASH} --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 ${COMMIT_HASH} --pretty="%b")"
COMMIT_TIME="$(git log -1 ${COMMIT_HASH} --pretty="%ct")"

if [ "${AUTHOR_NAME}" = "${COMMITTER_NAME}" ]; then
  CREDITS="${AUTHOR_NAME} authored & committed"
else
  CREDITS="${AUTHOR_NAME} authored & ${COMMITTER_NAME} committed"
fi

# Calculate approximate build time based on commit
DIFF_TIME=$(( ${CURRENT_TIME}-${COMMIT_TIME} ))
DISPLAY_TIME="$( printf "%02d" $(( ${DIFF_TIME} / 60 ))):$( printf "%02d" $(( ${DIFF_TIME} % 60 )))"


# Regex match co-author names
if [[ "${COMMIT_MESSAGE}" =~ Co-authored-by: ]]; then
    IFS=$'\n'
    CO_AUTHORS=($(echo "${COMMIT_MESSAGE}" | grep -o "\([A-Za-z]\+ \)\+[A-Za-z]\+"))

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
MATCHES=($(echo "${COMMIT_SUBJECT}" | grep -o "Merge \w\{40\}\b into \w\{40\}\b"))
if [ "${#MATCHES[@]}" -gt 0 ]; then
    IS_PR=true
    MATCHES=($(echo "${COMMIT_SUBJECT}" | grep -o "\w\{40\}\b"))
    for MATCH in "${MATCHES[@]}"
    do
        HASH="${MATCH}"
        BRANCH_NAME="$(git name-rev ${HASH} --name-only)"
        COMMIT_SUBJECT="${COMMIT_SUBJECT//$HASH/${BRANCH_NAME:-$HASH}}"
    done
fi
unset IFS

if [ $IS_PR ] && [ "${PULL_REQUEST_ID}" = "" ]; then
    echo "PULL_REQUEST_ID not defined."

    if [ "${STRICT_MODE}" = "true" ]; then
        echo "[Webhook]: CI detection failed. Strict mode was enabled and one or more variables was undefined."
        exit 1
    fi
fi

# Remove repo owner: symboxtra/project -> project
REPO_NAME=${REPO_SLUG#*/}

# Create appropriate link
if [ "${PULL_REQUEST_ID}" != "" ] || [ "${IS_PR}" = "true" ]; then
    if [ "${PULL_REQUEST_ID}" != "" ]; then
        URL="https://github.com/${REPO_SLUG}/pull/${PULL_REQUEST_ID}"
    else
        URL="https://github.com/${REPO_SLUG}/pulls"
    fi
else
    URL="https://github.com/${REPO_SLUG}/commit/${COMMIT_HASH}"
fi


TIMESTAMP=$(date --utc +%FT%TZ)
WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "'"${DISCORD_AVATAR}"'",
  "embeds": [ {
    "color": '${EMBED_COLOR}',
    "author": {
      "name": "'"${CI_PROVIDER}"' #'"${BUILD_NUMBER}"' - '"${REPO_NAME}"' - '"${STATUS_MESSAGE}"'",
      "url": "'"${BUILD_URL}"'",
      "icon_url": "'"${AVATAR}"'"
    },
    "title": "'"${COMMIT_SUBJECT}"'",
    "url": "'"${URL}"'",
    "description": "'"${COMMIT_MESSAGE}"\\n\\n"${CREDITS}"'",
    "fields": [
      {
        "name": "OS",
        "value": "'"${OS_NAME}"'",
        "inline": true
      },
      {
        "name": "Build Time",
        "value": "'"~${DISPLAY_TIME}"'",
        "inline": true
      },
      {
        "name": "Build ID",
        "value": "'"${BUILD_NUMBER%.*}CI"'",
        "inline": true
      },
      {
        "name": "Commit",
        "value": "'"[\`${COMMIT_HASH:0:7}\`](https://github.com/${REPO_SLUG}/commit/${COMMIT_HASH})"'",
        "inline": true
      },
      {
        "name": "Branch/Tag",
        "value": "'"[\`${BRANCH_NAME}\`](https://github.com/${REPO_SLUG}/tree/${BRANCH_NAME})"'",
        "inline": true
      },
      {
        "name": "Co-Authors",
        "value": "'"${CO_AUTHORS}"'",
        "inline": true
      }
    ],
    "footer": {
        "text": "'"v${WEBHOOK_VERSION}"'"
      },
    "timestamp": "'"${TIMESTAMP}"'"
  } ]
}'

curl -v --fail --progress-bar -A "${CI_PROVIDER}-Webhook" -H Content-Type:application/json -H X-Author:jmcker#6584 -d "${WEBHOOK_DATA}" "${WEBHOOK_URL}"

if [ $? -ne 0 ]; then
    echo -e "Webhook data:\\n${WEBHOOK_DATA}"
    echo -e "\\n[Webhook]: Unable to send webhook."

    # Don't exit with error unless we're in strict mode
    if [ "${STRICT_MODE}" = "true" ]; then
        exit 1
    fi
else
    echo -e "\\n[Webhook]: Successfully sent the webhook."
fi
