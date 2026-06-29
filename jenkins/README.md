# For users

Note that folder names should not contain -, recommended to replace it with \_.

## Adding your jobs

1. Add folder with your github username to config/jenkins.yml. Example:

<pre>
- script: >
  folder('username') {
    displayName: 'username'
    properties {
      authorizationMatrix {
        entries {
          user {
            name('username')
            permissions([ 'Credentials/Create', 'Credentials/Delete', 'Credentials/Update', 'Credentials/View', 'Job/Build', 'Job/Cancel' ])
          }
        }
      }
    }
  }
</pre>

If you have a project with possibly multiple users working on it then you can
also add folder for that project. In that case also add multiple user blocks
under entries.

2. Add your job into config/jenkins.yml

<pre>
- script: >
  multibranchPipelineJob('username/jobname') {
    displayName: 'jobname'
    branchSources {
      git {
          id('git')
          remote('project git https url')
      }
    }
    orphanedItemStrategy {
      discardOldItems {
          numToKeep(5)
      }
    }
  }
</pre>

3. Make a pull request
4. Ask admin to review and merge it
5. If configuration update automation does not work ask admin to manually
update the new configuration. Restarting Jenkins with "systemctl restart
jenkins" works.

## Building job using webhook

[Generic Webhook Trigger](https://plugins.jenkins.io/generic-webhook-trigger/)
plugin is installed.

- Get API Token from Jenkins.
  - Go to https://jenkins.scheme.org -> Top right menu -> Security -> Add new token.
- The webhook url is: https://jenkins.scheme.org/generic-webhook-trigger/invoke
- Add webhook trigger into your Jenkinsfile


<pre><code>
pipeline {
    agent { any }

    triggers {
      GenericTrigger(
        genericVariables: [[key: 'ref', value: '$.ref']],
        causeString: 'Triggered on $ref',
        printContributedVariables: true,
        printPostContent: true,
        silentResponse: false,
        shouldNotFlatten: false,
        regexpFilterText: '$ref',
        regexpFilterExpression: 'refs/heads/' + BRANCH_NAME
      )
    }
    ...
}
</pre></code>

## Installed plugins

For installed plugins see Dockerfile.jenkins

# For maintainers

Docker based Jenkins setup through Configuration-as-Code

## Running

1. Run `create-keys.sh` to generate SSH keys used for Jenkins controller to talk to Jenkins agent;
2. Run `echo -n 'password' > adminpassword` to setup password for admin user (watchout to not add newlines);
3. Run `echo "DOCKER_GROUP=$(getent group docker | cut -d: -f3)" > .env` to setup agent's group so it can access docker socket;
4. Run `docker compose up -d`;
5. (Optionally) Add `update.sh` script to be run by cron periodically.

If all went well jenkins should be reachable on `localhost:8080`, login with user `admin` and password from step 2.

## User permissions and per-project secrets

Jobs often need secrets, however these secrets should be scoped per-user / project. A solution is therefore to use folders and matrix authentication plugin. For each user or project a top level folder should be created. In this folder administrator configures full permissions to necessary users (folder view -> Configure -> General -> Enable project-based-security). Users are then able to and edit secrets, but only for their jobs.

## Points of Improvement

1. Fix the goofy docker group mess;
2. Externalize user management (eg LDAP);
3. Use vaults for secret storage;
4. Change agent from persistent ssh to an adhoc provisioned instance.
