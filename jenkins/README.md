# Docker based Jenkins setup through Configuration-as-Code

## Running

1. Run `create-keys.sh` to generate SSH keys used for Jenkins controller to talk to Jenkins agent;
2. Run `echo -n 'password' > adminpassword` to setup password for admin user (watchout to not add newlines);
3. Run `echo "DOCKER_GROUP=$(getent group docker | cut -d: -f3)" > .env` to setup agent's group so it can access docker socket;
4. Run `docker compose up -d`;
5. (Optionally) Add `update.sh` script to be run by cron periodically.

If all went well jenkins should be reachable on `localhost:8080`, login with user `admin` and password from step 2.

## Workflow for setting up jobs

1. A pull request is initiated on a git platform where this configuration is hosted, with necessary changes in `jenkins.yml` jobs section;
2. Maintainer(s) review the change, merge if appropriate;
3. Either periodically, manually, or on some way set up trigger, machine hosting Jenkins controller does a `git pull` and `docker compose up -d --build`, after which the changes should appear on CI.

## User permissions and per-project secrets

Jobs often need secrets, however these secrets should be scoped per-user / project. A solution is therefore to use folders and matrix authentication plugin. For each user or project a top level folder should be created. In this folder administrator configures full permissions to necessary users (folder view -> Configure -> General -> Enable project-based-security). Users are then able to and edit secrets, but only for their jobs.

## Points of Improvement

1. Fix the goofy docker group mess;
2. Externalize user management (eg LDAP);
3. Use vaults for secret storage;
4. Change agent from persistent ssh to an adhoc provisioned instance.
