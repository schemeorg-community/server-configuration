# For users

Note that folder names should not contain -, recommended to replace it with \_.

## Adding your jobs

1. Add folder with your github username to config/jenkins.yml. Example:

    \- script: >
      folder('<username>') {
        displayName: '<username>'
        properties {
          authorizationMatrix {
            entries {
              user {
                name('<username>')
                permissions([ 'Credentials/Create', 'Credentials/Delete', 'Credentials/Update', 'Credentials/View', 'Job/Build', 'Job/Cancel' ])
              }
            }
          }
        }
      }

If you have a project with possibly multiple users working on it then you can
also add folder for that project. In that case also add multiple user blocks
under entries.

2. Add your job into config/jenkins.yml

    - script: >
      multibranchPipelineJob('<username>/<jobname>') {
        displayName: '<jobname>'
        branchSources {
          git {
              id('git')
              remote('<project git ssh url>')
          }
        }
        orphanedItemStrategy {
          discardOldItems {
              numToKeep(5)
          }
        }
      }

3. Make a pull request
4. Ask admin to review and merge it
    3.1 For admins: User should also be added to Jenkins with same name as
    github username and password sent to pull request maker.
5. If configuration update automation does not work ask admin to manually
update the new configuration. Restarting Jenkins with systemctl restart jenkins
works.

## Building job using curl

    curl -X POST https://<your username>:<token>@jenkins.scheme.org/job/<job directory>/job/<job name>/job/<branch>/build?delay=0sec"


So for example to build foreign-c:

    curl -X POST https://<your username>:<token>@jenkins.scheme.org/job/foreign_c/job/foreign-c/job/master/build?delay=0sec"

You can get the link also from the **Build now** button on the job webpage.
Right click and **copy link**.

To get token login and go to "Security" settings of your user menu.

### Sourcehut example

This is example for how to start build automatically in Jenkins when code is
pushed to git. It's for Sourcehut but should give a general idea about how to
do it Github/Gitlab/BitBucket and such.

Add new secret file in path ${HOME}/netrc-scheme-jenkins with content:

    machine jenkins.scheme.org
    username <username>
    password <token>

Then add this .build.yml into your repository:

   image: alpine/edge
   secrets:
     - <your secrets id>
     tasks:
         - trigger-jenkins-build: |
             branch=$(echo "$GIT_REF" | awk '{split($0,a,"/"); print(a[3])}')
             curl --netrc-file ${HOME}/netrc-scheme-jenkins -X POST "https://jenkins.scheme.org/job/<job directory>/job/<job name>/job/${branch}/build?delay=0sec"

## Jenkinsfile for testing code on many implementations

This Jenkinsfile uses
[https://github.com/Retropikzel/compile-r7rs](https://github.com/Retropikzel/compile-r7rs)
to test code on all supported implementations. It tests with R7RS implementations
but to test with r6rs-implementations change the --list-r7rs-schemes to
--list-r6rs-schemes.

Change the "your-project-" part of docker tags too.

    pipeline {
        agent any

        options {
            disableConcurrentBuilds()
            buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        }

        stages {
            stage('Tests') {
                steps {
                    script {
                        def implementations = sh(script: 'docker run retropikzel1/compile-r7rs:chibi sh -c "compile-r7rs --list-r7rs-schemes"', returnStdout: true).split()

                        implementations.each { implementation->
                            stage("${implementation}") {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "docker build --build-arg COMPILE_R7RS=${implementation} --tag=your-project-test-${implementation} -f Dockerfile.test ."
                                    sh "docker run -v ${WORKSPACE}:/workdir -w /workdir -t your-project-test-${implementation} sh -c \"compile-r7rs -I . -o test test.scm\""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
