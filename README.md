# CI Service 🡒 Discord Webhook #

If you've been looking for a way to get build reports from your CI service to [Discord](https://discordapp.com), look no further.
You've come to the right place.

## Providers ##

The following CI services are currently supported and will be autodetected when you run the appropriate ```send.XXX``` script:

| CI Service | Script | Support Status |
|---|---|---|
| AppVeyor | ```send.ps1``` | [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/r06uj8lyogqiurmn/branch/master?svg=true)](https://ci.appveyor.com/project/symboxtra/universal-ci-discord-webhook/branch/master) |
| Jenkins | ```send.ps1``` ```send.sh``` | [![Jenkins Build Status](https://jenkins.symboxtra.dynu.net/buildStatus/icon?job=universal-ci-discord-webhook/master)](https://jenkins.symboxtra.dynu.net/job/universal-ci-discord-webhook/job/master/) |
| Travis | ```send.sh``` | [![Travis Build Status](https://travis-ci.org/symboxtra/universal-ci-discord-webhook.svg?branch=master)](https://travis-ci.org/symboxtra/universal-ci-discord-webhook/builds) |

We're always looking to support more! Feel free to implement support yourself or open an issue and ask. 

## Guide ##
1.  Create a Webhook in your Discord Server ([Guide](https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks)).

1.  Copy the **Webhook URL**.

1.  Go to your CI platform's global or repository specific settings
    and look for a section entitled **Environment** or **Environment Variables**
    
1.  Add an environment variable named `WEBHOOK_URL` and paste
    the copied **Webhook URL** from the previous step.
    
    It's wise to keep this URL private.
    
    Most platforms support Secure Environment Variables, offer some form of encryption, or allow you to prevent the value from showing in the build logs entirely.

    #### Example from [Travis CI](https://travis-ci.org) ####
    ![Add environment variable in Travis CI](https://i.imgur.com/UfXIoZn.png)
    
    

1.  Add the following commands to the ```success``` and ```failure``` sections of your CI provider's pipeline.

    #### Example for [AppVeyor](https://ci.appveyor.com) ####
    ```yaml
    on_success:
    - ps: Invoke-RestMethod https://raw.githubusercontent.com/symboxtra/universal-ci-discord-webhook/master/send.ps1 -o send.ps1
    - ps: if ($env:WEBHOOK_URL.length -ne 0) { ./send.ps1 success $env:WEBHOOK_URL } else { Write-Host "WEBHOOK_URL inaccessible." } # Send Webhook only when secure env vars can be decrypted
    
    on_failure:
    - ps: Invoke-RestMethod https://raw.githubusercontent.com/symboxtra/universal-ci-discord-webhook/master/send.ps1 -o send.ps1
    - ps: if ($env:WEBHOOK_URL.length -ne 0) { ./send.ps1 failure $env:WEBHOOK_URL } # Send Webhook only when secure env vars can be decrypted
    ```
    

    #### Example for [Travis CI](https://travis-ci.org) ####
    ```yaml
    after_success:
      - curl https://raw.githubusercontent.com/symboxtra/travis-ci-discord-webhook/master/send.sh > send.sh && chmod +x send.sh
      - ./send.sh success $WEBHOOK_URL
    after_failure:
      - curl https://raw.githubusercontent.com/symboxtra/travis-ci-discord-webhook/master/send.sh > send.sh && chmod +x send.sh
      - ./send.sh failure $WEBHOOK_URL
    ```
    
    The first line downloads the script file and makes it executable (if applicable).
    The second line sends the webhook.
    
## Strict Mode ##

If you prefer that the script fail and return a non-zero exit code upon any error, strict mode can be enabled by passing ```strict``` as the third parameter to the script. This is mainly intended for testing.

```
./send.sh success $WEBHOOK_URL strict
```
    
## Caveats ##

On some CI platforms, secure environment variables are not available during third party pull request builds. The webhook will not send notification of these builds. 

To prevent your CI build from erroring, the scripts in this repository exit with a non-zero exit code only when ```strict``` mode is enabled. For added safety/sanity, the script call can be wrapped in a length check on ```WEBHOOK_URL```, as seen in the AppVeyor example, or can be combined with ```|| true``` to eat any possible non-zero exit codes.
