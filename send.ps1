# Author: Symboxtra Software
# Author of Travis-CI-Discord Webhook and AppVeyor-Discord-Webhook:
#    Sankarsan Kampa (a.k.a. k3rn31p4nic)
# License: MIT

$WEBHOOK_VERSION="2.0.0.0"

$OS_NAME="Windows"

$STATUS="$($args[0])"
$WEBHOOK_URL="$($args[1])"
$CURRENT_TIME=[int64](([datetime]::UtcNow)-(get-date "1/1/1970")).TotalSeconds

$STRICT_MODE=$false
if ("$($args[3])" -eq "strict") {
    $STRICT_MODE=$true
}

if (!$WEBHOOK_URL) {
    Write-Output "WARNING!"
    Write-Output "You need to pass the WEBHOOK_URL environment variable as the second argument to this script."
    Write-Output "For details & guidance, visit: https://github.com/symboxtra/universal-ci-discord-webhook"

    if ($STRICT_MODE) {
        exit 1
    }
    else {
        exit
    }
}

# The following variables must be defined for each CI service:
# $CI_PROVIDER=""      # Name of CI provider
# $DISCORD_AVATAR=""   # Large avatar for Discord user icon
# $SUCCESS_AVATAR=""   # Avatar for successful build
# $FAILURE_AVATAR=""   # Avatar for failed build
# $UNKNOWN_AVATAR=""   # Avatar for unknown build
# $BRANCH_NAME=""      # Branch name
# $COMMIT_HASH=""      # Hash of current commit
# $PULL_REQUEST_ID=""  # Id of PR if present
# $REPO_SLUG=""        # "owner/project" format for GitHub
# $BUILD_NUMBER=""     # Identifier for build
# $BUILD_URL=""        # Link to the build page

# These conditions come from the codecov bash script
# Apache License Version 2.0, January 2004
# https://github.com/codecov/codecov-bash/blob/master/LICENSE
if ( "${env:JENKINS_URL}" -ne "" ) {

    $CI_PROVIDER="Jenkins"
    $DISCORD_AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"
    $SUCCESS_AVATAR="https://jenkins.io/images/logos/cute/cute.png"
    $FAILURE_AVATAR="https://jenkins.io/images/logos/fire/fire.png"
    $UNKNOWN_AVATAR="https://wiki.jenkins.io/download/attachments/2916393/headshot.png?version=1&modificationDate=1302753947000&api=v2"

    # BRANCH_NAME
    if ( "${env:ghprbSourceBranch}" -ne "" ) {
        $BRANCH_NAME="${env:ghprbSourceBranch}"
    }
    elseif ( "${env:GIT_BRANCH}" -ne "" ) {
        $BRANCH_NAME="${env:GIT_BRANCH}"
    }
    elseif ( "${env:BRANCH_NAME}" -ne "" ) {
        $BRANCH_NAME="${env:BRANCH_NAME}"
    }

    # COMMIT_HASH
    if ( "${env:ghprbActualCommit}" -ne "" ) {
        $COMMIT_HASH="${env:ghprbActualCommit}"
    }
    elseif ( "${env:GIT_COMMIT}" -ne "" ) {
        $COMMIT_HASH="${env:GIT_COMMIT}"
    }

    # PULL_REQUEST_ID
    if ( "${env:ghprbPullId}" -ne "" ) {
        $PULL_REQUEST_ID="${env:ghprbPullId}"
    }
    elseif ( "${env:CHANGE_ID}" -ne "" ) {
        $PULL_REQUEST_ID="${env:CHANGE_ID}"
    }

    $REPO_URL="$(git remote get-url origin)"
    $REPO_SLUG=$REPO_URL -replace '.*github.com/', ''
    $REPO_SLUG=$REPO_SLUG -replace '[.]git.*', ''

    $BUILD_NUMBER="${env:BUILD_NUMBER}"
    $BUILD_URL="${env:BUILD_URL}/console"

}
elseif ( "${env:CI}" -eq "True" -And "${env:APPVEYOR}" -eq "True" ) {

    $CI_PROVIDER="AppVeyor"
    $DISCORD_AVATAR="https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Appveyor_logo.svg/256px-Appveyor_logo.svg.png"
    $SUCCESS_AVATAR="https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Appveyor_logo.svg/256px-Appveyor_logo.svg.png"
    $FAILURE_AVATAR="https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Appveyor_logo.svg/256px-Appveyor_logo.svg.png"
    $UNKNOWN_AVATAR="https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Appveyor_logo.svg/256px-Appveyor_logo.svg.png"

    $BRANCH_NAME="${env:APPVEYOR_REPO_BRANCH}"
    $COMMIT_HASH="${env:APPVEYOR_REPO_COMMIT}"
    $PULL_REQUEST_ID="$env:APPVEYOR_PULL_REQUEST_NUMBER"

    $REPO_SLUG="$env:APPVEYOR_REPO_NAME"
    $BUILD_NUMBER="$env:APPVEYOR_BUILD_NUMBER"
    $BUILD_URL="https://ci.appveyor.com/project/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/build/$env:APPVEYOR_BUILD_VERSION"

}
else {
    Write-Output "No CI service detected. Service not found or not supported? Open an issue on GitHub!"

    if ($STRICT_MODE) {
        exit 1
    }
    else {
        exit
    }
}

# Check that all variables were found
$ALL_FOUND=$true

if ( "${CI_PROVIDER}" -eq "") {
    Write-Output "CI_PROVIDER not defined."
    $ALL_FOUND=$false
}
if ( "${DISCORD_AVATAR}" -eq "") {
    Write-Output "DISCORD_AVATAR not defined."
    $ALL_FOUND=$false
}
if ( "${SUCCESS_AVATAR}" -eq "") {
    Write-Output "SUCCESS_AVATAR not defined."
    $ALL_FOUND=$false
}
if ( "${FAILURE_AVATAR}" -eq "") {
    Write-Output "FAILURE_AVATAR not defined."
    $ALL_FOUND=$false
}
if ( "${UNKNOWN_AVATAR}" -eq "") {
    Write-Output "UNKNOWN_AVATAR not defined."
    $ALL_FOUND=$false
}
if ( "${BRANCH_NAME}" -eq "") {
    Write-Output "BRANCH_NAME not defined."
    $ALL_FOUND=$false
}
if ( "${COMMIT_HASH}" -eq "") {
    Write-Output "COMMIT_HASH not defined."
    $ALL_FOUND=$false
}
if ( "${REPO_SLUG}" -eq "") {
    Write-Output "REPO_SLUG not defined."
    $ALL_FOUND=$false
}
if ( "${BUILD_NUMBER}" -eq "") {
    Write-Output "BUILD_NUMBER not defined."
    $ALL_FOUND=$false
}
if ( "${BUILD_URL}" -eq "") {
    Write-Output "BUILD_URL not defined."
    $ALL_FOUND=$false
}

if ($STRICT_MODE -And !$ALL_FOUND) {
    Write-Output "[Webhook]: CI detection failed. Strict mode was enabled and one or more variables was undefined."
    exit 1
}

""
Write-Output "[Webhook]: ${CI_PROVIDER} CI detected."
Write-Output "[Webhook]: Sending webhook to Discord..."
""

Switch ($STATUS) {
  "success" {
    $EMBED_COLOR=3066993
    $STATUS_MESSAGE="Passed"
    $AVATAR="${SUCCESS_AVATAR}"
    Break
  }
  "failure" {
    $EMBED_COLOR=15158332
    $STATUS_MESSAGE="Failed"
    $AVATAR="${FAILURE_AVATAR}"
    Break
  }
  default {
    $EMBED_COLOR=8421504
    $STATUS_MESSAGE="Unknown"
    $AVATAR="${UNKNOWN_AVATAR}"
    Break
  }
}

$AUTHOR_NAME="$(git log -1 ${COMMIT_HASH} --pretty="%aN")"
$COMMITTER_NAME="$(git log -1 ${COMMIT_HASH} --pretty="%cN")"
$COMMIT_SUBJECT="$(git log -1 ${COMMIT_HASH} --pretty="%s")"
$COMMIT_MESSAGE="$(git log -1 ${COMMIT_HASH} --pretty="%b")"
$COMMIT_TIME="$(git log -1 ${COMMIT_HASH} --pretty="%ct")"

if (${AUTHOR_NAME} -eq ${COMMITTER_NAME}) {
    $CREDITS="${AUTHOR_NAME} authored & committed"
}
else {
    $CREDITS="${AUTHOR_NAME} authored & ${COMMITTER_NAME} committed"
}

# Calculate approximate build time based on commit
$BUILD_TIME=${CURRENT_TIME}-${COMMIT_TIME}
$TIME_STAMP=$([timespan]::fromseconds(${BUILD_TIME}))
$DISPLAY_TIME=$("{0:mm:ss}" -f ([datetime]${TIME_STAMP}.Ticks))

# Regex match co-author names
if (${COMMIT_MESSAGE} -match 'Co-authored-by:') {

    [array] $RESULTS=[regex]::Matches("${COMMIT_MESSAGE}", '\w+\s\w+')
    if ($RESULTS.Count -gt 0)
    {
        $CO_AUTHORS=$RESULTS.Value
    }
    $CO_AUTHORS = ${CO_AUTHORS} -join ', '
}
else {
    $CO_AUTHORS="None"
}

# Replace git hashes in merge commits
if (${COMMIT_SUBJECT} -match 'Merge \w{40}\b into \w{40}\b') {

    $IS_PR=$true
    [array] $RESULTS=[regex]::Matches("${COMMIT_SUBJECT}", '\w{40}\b')
    foreach ($MATCH in $RESULTS)
    {
        $HASH=$MATCH.Value
        $BRANCH_NAME="$(git name-rev ${HASH} --name-only)"
        if ($BRANCH_NAME) {
            $COMMIT_SUBJECT="${COMMIT_SUBJECT}" -replace "${HASH}", "${BRANCH_NAME}"
        }
    }

}

if ( ${IS_PR} -AND "${PULL_REQUEST_ID}" -eq "") {
    Write-Output "PULL_REQUEST_ID not defined."

    if ( ${STRICT_MODE} ) {
        Write-Output "[Webhook]: CI detection failed. Strict mode was enabled and one or more variables was undefined."
        exit 1
    }
}

# Remove repo owner: symboxtra/project -> project
$REPO_NAME=${REPO_SLUG} -replace '^[^/]*\/', ''

# Create appropriate link
if ("${PULL_REQUEST_ID}" -ne "" -Or ${IS_PR}) {
    if (${PULL_REQUEST_ID}) {
        $URL="https://github.com/${REPO_SLUG}/pull/${PULL_REQUEST_ID}"
    }
    else {
        $URL="https://github.com/${REPO_SLUG}/pulls"
    }
}
else {
    $URL="https://github.com/${REPO_SLUG}/commit/${COMMIT_HASH}"
}

$TIMESTAMP="$(Get-Date -format s)Z"
$WEBHOOK_DATA="{
  ""username"": """",
  ""avatar_url"": ""${DISCORD_AVATAR}"",
  ""embeds"": [ {
    ""color"": ${EMBED_COLOR},
    ""author"": {
      ""name"": ""#${BUILD_NUMBER} - ${REPO_NAME} - ${STATUS_MESSAGE}"",
      ""url"": ""${BUILD_URL}"",
      ""icon_url"": ""${AVATAR}""
    },
    ""title"": ""${COMMIT_SUBJECT}"",
    ""url"": ""${URL}"",
    ""description"": ""${COMMIT_MESSAGE}\n\n${CREDITS}"",
    ""fields"": [
      {
      	""name"": ""OS"",
      	""value"": ""${OS_NAME}"",
      	""inline"": true
      },
      {
        ""name"": ""Build Time"",
        ""value"": ""~${DISPLAY_TIME}"",
        ""inline"": true
      },
      {
      	""name"": ""Build ID"",
      	""value"": ""${BUILD_NUMBER}CI"",
      	""inline"": true
      },
      {
        ""name"": ""Commit"",
        ""value"": ""[``$($COMMIT_HASH.substring(0, 7))``](https://github.com/${REPO_SLUG}/commit/${COMMIT_HASH})"",
        ""inline"": true
      },
      {
        ""name"": ""Branch/Tag"",
        ""value"": ""[``${BRANCH_NAME}``](https://github.com/${REPO_SLUG}/tree/${BRANCH_NAME})"",
        ""inline"": true
      },
      {
        ""name"": ""Co-Authors"",
        ""value"": ""${CO_AUTHORS}"",
        ""inline"": true
      }
    ],
    ""footer"": {
        ""text"": ""v${WEBHOOK_VERSION}""
      },
    ""timestamp"": ""${TIMESTAMP}""
  } ]
}"

Invoke-RestMethod -Uri "${WEBHOOK_URL}" -Method "POST" -UserAgent "${CI_PROVIDER}-Webhook" `
  -ContentType "application/json" -Header @{"X-Author"="jmcker#6584"} `
  -Body ${WEBHOOK_DATA}

if ( -not $? ) {
    ""
    Write-Output "Webhook Data:\n${WEBHOOK_DATA}"
    Write-Output "[Webhook]: Unable to send webhook." -Foreground Red

    # Don't exit with error unless we're in strict mode
    if ($STRICT_MODE) {
        exit 1
    }
}
else {
    Write-Output "[Webhook]: Successfully sent the webhook."
}

# Please note: this has never actually been tested with a Jenkins build on Windows.
# There might be some issues. Can we fix it? Yes, we can. -- Bob the Builder
