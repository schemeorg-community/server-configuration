(import (scheme base)
        (scheme file)
        (srfi 1))

(cond-expand
 ((library (srfi 166))
  (import (only (srfi 166) pretty show)))
 (else))

(cond-expand
 ((library (srfi 166))
  (begin
    (define (pretty-print x)
      (show #t (pretty x)))))
 (else
  (begin
    (define (pretty-print x)
      (write x)
      (newline)))))

(define rest cdr)

(define (path-append a b)
  (string-append a "/" b))

(define (generator->list g)  ; Subset of the behavior in SRFI 158.
  (let loop ((xs '()))
    (let ((x (g)))
      (if (eof-object? x) (reverse xs) (loop (cons x xs))))))

(define human-users
  '((0 "lassi" "Lassi Kortela")
    (1 "arthur" "Arthur Gleckler")
    (2 "hga" "Harold Ancell")
    (3 "feeley" "Marc Feeley")
    (4 "jeronimo" "Jeronimo Pellegrini")
    (5 "graywolf" "graywolf")))

(define human-user-ordinal first)
(define human-user-name second)
(define human-user-display-name third)

(define (human-user-id human-user)
  (+ 1000 (human-user-ordinal human-user)))

(define (human-user-groups human-user)
  '("users" "sudo" "docker"))

(define (ssh-key-tasks* user-name human-user-name)
  (map (lambda (key)
         `(task
           (title ,(string-append "add key for " human-user-name))
           (authorized-key
            (user ,user-name)
            (key ,(string-append key " " human-user-name)))))
       (with-input-from-file (path-append "keys" human-user-name)
         (lambda () (generator->list read-line)))))

(define (ssh-key-tasks user-name)
  (ssh-key-tasks* user-name user-name))

(define (human-user-tasks human-user)
  `((task
     (title ,(string-append "make user " (human-user-name human-user)))
     (user
      (uid ,(human-user-id human-user))
      (name ,(human-user-name human-user))
      (comment ,(human-user-display-name human-user))
      (group ,(first (human-user-groups human-user)))
      (groups ,(rest (human-user-groups human-user)))
      (shell "/bin/bash")))
    ,@(ssh-key-tasks (human-user-name human-user))))

(define sites
  '(("api" 0)
    ("apps" 22)
    ("books" 23)
    ("chat" 38)
    ("comm" 8)
    ("community" 26)
    ("conservatory" 34)
    ("containers" 20)
    ("cookbook" 25)
    ("docs" 2)
    ("events" 16)
    ("files" 13)
    ("get" 50)
    ("gitea" 40)
    ("go" 36)
    ("groups" 32)
    ("lists" 10)
    ("man" 27)
    ("persist" 7)
    ("planet" 18)
    ("registry" 6)
    ("research" 15)
    ("server" 12)
    ("standards" 14)
    ("test" 9)
    ("try" 17)
    ("video" 28)
    ("web" 11)
    ("wiki" 70)
    ("workshop" 44)))

(define site-name first)
(define site-ordinal second)

(define (site-by-name name)
  (or (assoc name sites)
      (error "No site named" name)))

;; User and group names longer than this are impractical as they mess
;; up `ls -l` listings and such.
(define unix-name-max 14)

(define (site-unix-name prefix site)
  (let* ((name (site-name site))
         (name-len (string-length name))
         (name-max (- unix-name-max (string-length prefix))))
    (string-append prefix (string-copy name 0 (min name-len name-max)))))

(define staging-site-names
  '("api" "docs" "get" "wiki" "workshop"))

(define (staging-site? site)
  (not (not (member (site-name site) staging-site-names))))

;; Site IDs can be used as Unix user and group IDs as well as TCP/UDP
;; port numbers.

(define (production-site-id site)
  (+ 4000 (site-ordinal site)))

(define (staging-site-id site)
  (and (staging-site? site)
       (+ 7000 (site-ordinal site))))

(define (site-tasks site-id site-unix-name site-home . subdirectories)
  `((task
     (title "make group")
     (group
      (gid ,site-id)
      (name ,site-unix-name)))
    (task
     (title "make user")
     (user
      (uid ,site-id)
      (name ,site-unix-name)
      (group ,site-unix-name)
      (groups ("users"))
      (comment ,site-unix-name)
      (home ,site-home)
      (shell "/bin/bash")
      (move-home true)))
    (task
     (title "chmod home dir")
     (file
      (path ,site-home)
      (mode "u=rwX,g=rX,o=rX")
      (follow false)
      (recurse false)))
    (task
     (title "chown home dir")
     (file
      (path ,site-home)
      (state "directory")
      (owner ,site-unix-name)
      (group "users")
      (follow false)
      (recurse true)))
    ,@(map (lambda (subdir)
             (let ((dir (string-append site-home "/" subdir)))
               `(task
                 (title ,(string-append "make " dir " dir"))
                 (file
                  (path ,dir)
                  (state "directory")
                  (owner ,site-unix-name)
                  (group "users")
                  (mode "u=rwX,g=rwX,o=rX")
                  (follow false)
                  (recurse true)))))
           subdirectories)))

(define (production-site-tasks site-name . subdirectories)
  (let ((site (site-by-name site-name)))
    (apply site-tasks
           (production-site-id site)
           (site-unix-name "prod-" site)
           (string-append "/production/" site-name)
           subdirectories)))

(define (staging-site-tasks site-name . subdirectories)
  (let ((site (site-by-name site-name)))
    (unless (staging-site? site)
      (error "No staging site for" site))
    (apply site-tasks
           (staging-site-id site)
           (site-unix-name "stag-" site)
           (string-append "/staging/" site-name)
           subdirectories)))

(define (write-top-level-expressions . exps)
  (for-each pretty-print exps))

(write-top-level-expressions

 `(options
   (var pipelining true))

 `(groups
   (group
    (name schemeorg)
    (hosts
     (host
      (name tuonela)
      (vars
       (var ansible-host "192.210.181.186")
       (var ansible-python-interpreter "/usr/bin/python3"))))))

 `(playbooks

   (playbook
    (name schemeorg)
    (hosts tuonela)
    (become true)
    (roles

     apt-upgrade
     apt-comfort
     hostname
     motd
     sudo
     firewall
     docker
     antivirus
     postgresql
     build-user
     human-users
     ;;make-production-api
     ;;make-staging-api
     make-production-docs
     make-staging-docs
     make-production-registry
     make-production-persist
     make-production-planet
     make-production-apps
     make-production-books
     make-production-chat
     make-production-comm
     make-production-community
     make-production-cookbook
     make-production-gitea
     make-production-go
     make-production-groups
     make-production-man
     make-production-test
     make-production-web
     make-production-wiki
     make-staging-wiki
     make-production-workshop
     make-staging-workshop
     make-production-events
     make-production-files
     make-production-get
     make-staging-get
     make-production-conservatory
     make-production-containers
     make-production-lists
     make-production-research
     make-production-standards
     make-production-server
     make-production-try
     make-production-video
     nginx
     sshd)))

 `(roles

   (role
    (name apt-upgrade)
    (tasks
     (task
      (title "upgrade all apt packages to latest versions")
      (apt
       (update-cache true)
       (upgrade true)))))

   (role
    (name apt-comfort)
    (tasks
     (task
      (title "text editors")
      (apt
       (name
        ("emacs-nox"
         "mg"
         "nano"
         "vim"))))
     (task
      (title "other tools")
      (apt
       (name
        ("build-essential"
         "curl"
         "dnsutils"
         "fdupes"
         "git"
         "htop"
         "httpie"
         "jq"
         "rdiff-backup"
         "rsync"
         "silversearcher-ag"
         "stow"
         "tmux"
         "tree"
         "unzip"
         "wget"))))))

   (role
    (name hostname)
    (tasks
     (task
      (title "set hostname")
      (hostname (name "tuonela.scheme.org")))))

   (role
    (name motd)
    (tasks
     (task
      (title "set login greeting message")
      (copy
       (dest "/etc/motd")
       (src "files/motd")
       (owner "root")
       (group "root")
       (mode "u=rw,g=r,o=r")))))

   (role
    (name sudo)
    (tasks
     (task
      (title "install sudo")
      (apt (name "sudo")))
     (task
      (title "enable passwordless sudo")
      (lineinfile
       (validate "visudo -cqf %s")
       (path "/etc/sudoers")
       (regexp "%sudo")
       (line "%sudo ALL=(ALL:ALL) NOPASSWD:ALL")))
     (task
      (title "do not create .sudo_as_admin_successful")
      (lineinfile
       (validate "visudo -cqf %s")
       (path "/etc/sudoers")
       (line "Defaults !admin_flag")))))

   (role
    (name sshd)
    (tasks
     (task
      (title "deny ssh password authentication")
      (lineinfile
       (dest "/etc/ssh/sshd_config")
       (regexp "^#?PasswordAuthentication")
       (line "PasswordAuthentication no"))
      (notify "restart ssh")))
    (handlers
     (handler
      (title "restart ssh")
      (service
       (name "sshd")
       (state "restarted")))))

   (role
    (name firewall)
    (tasks
     (task
      (title "install ufw")
      (apt (name "ufw")))
     (task
      (title "allow ssh")
      (ufw
       (rule allow)
       (proto tcp)
       (port ssh)))
     (task
      (title "allow http")
      (ufw
       (rule allow)
       (proto tcp)
       (port http)))
     (task
      (title "allow https")
      (ufw
       (rule allow)
       (proto tcp)
       (port https)))
     (task
      (title "enable firewall with default policy to deny all")
      (ufw
       (state enabled)
       (policy deny)))))

   (role
    (name docker)
    (tasks
     (task
      (title "install docker")
      (apt
       (name
        ("docker.io"
         "docker-compose"))))))

   (role
    (name antivirus)
    (tasks
     (task
      (title "install clamav")
      (apt (name "clamav-base")))))

   (role
    (name postgresql)
    (tasks
     (task
      (title "install postgresql")
      (apt (name "postgresql")))
     (task
      (title "backup system pg_hba.conf to pg_hba.conf.orig")
      (copy
       (dest "/etc/postgresql/15/main/pg_hba.conf.orig")
       (src "/etc/postgresql/15/main/pg_hba.conf")
       (remote-src true)
       (mode "0444")
       (force false)))
     (task
      (title "change peer to md5 so unix domain sockets work")
      (lineinfile
       (dest "/etc/postgresql/15/main/pg_hba.conf")
       (regexp "^local.*all.*all")
       (line "local all all md5"))
      (notify "restart postgresql"))
     (task
      (title "start postgresql now and at every boot")
      (service
       (name "postgresql")
       (enabled true)
       (state "started"))))
    (handlers
     (handler
      (title "restart postgresql")
      (service
       (name "postgresql")
       (state "restarted")))))

   (role
    (name build-user)
    (tasks
     (task
      (title "make build group")
      (group
       (gid 1100)
       (name "build")))
     (task
      (title "make build user")
      (user
       (uid 1100)
       (name "build")
       (comment "We can build packages from source using this account")
       (group "build")
       (shell "/bin/bash")
       (home "/build")))))

   (role
    (name human-users)
    (tasks
     ,@(append-map human-user-tasks
                   human-users)))

   (role
    (name make-production-docs)
    (tasks
     ,@(production-site-tasks "docs" "www")))

   (role
    (name make-staging-docs)
    (tasks
     ,@(staging-site-tasks "docs" "www")))

   (role
    (name make-production-api)
    (tasks
     ,@(production-site-tasks "api")
     (task
      (title "make run script")
      (copy
       (dest "/production/api/run")
       (src "run")
       (mode "u=rwx,g=rx,o=rx"))
      (notify "restart services")))
    (handlers
     (handler
      (title "restart services")
      (command (cmd "true")))))

   (role
    (name make-staging-api)
    (tasks
     ,@(staging-site-tasks "api")
     ;;(task
     ;; (title "install packages based on package.json")
     ;; (npm
     ;;  (path "/staging/api")))
     (task
      (title "make run script")
      (copy
       (dest "/staging/api/run")
       (src "run")
       (mode "u=rwx,g=rx,o=rx"))
      (notify "restart services")))
    (handlers
     (handler
      (title "restart services")
      (command (cmd "true")))))

   (role
    (name make-production-registry)
    (tasks
     ,@(production-site-tasks "registry" "www")))

   (role
    (name make-production-persist)
    (tasks
     ,@(production-site-tasks "persist" "www")))

   (role
    (name make-production-planet)
    (tasks
     ,@(production-site-tasks "planet" "www")
     (task
      (title "add cron job to check the feeds")
      (copy
       (dest "/etc/cron.d/scheme-prod-planet")
       (content
        "0 0-23/6 * * * prod-planet /production/planet/planet/planet.sh\n")
       (mode "644")
       (owner "0")
       (group "0")))))

   (role
    (name make-production-apps)
    (tasks
     ,@(production-site-tasks "apps" "www")))

   (role
    (name make-production-books)
    (tasks
     ,@(production-site-tasks "books" "www")))

   (role
    (name make-production-chat)
    (tasks
     ,@(production-site-tasks "chat" "www")))

   (role
    (name make-production-comm)
    (tasks
     ,@(production-site-tasks "comm" "www")))

   (role
    (name make-production-community)
    (tasks
     ,@(production-site-tasks "community" "www")))

   (role
    (name make-production-cookbook)
    (tasks
     ,@(production-site-tasks "cookbook" "www")))

   (role
    (name make-production-gitea)
    (tasks
     ,@(production-site-tasks "gitea")
     (task
      (title "make systemd prod-gitea.service")
      (copy
       (dest "/etc/systemd/system/prod-gitea.service")
       (src "prod-gitea.service")
       (owner "root")
       (group "root")
       (mode "0644")))))

   (role
    (name make-production-man)
    (tasks
     ,@(production-site-tasks "man" "www")))

   (role
    (name make-production-test)
    (tasks
     ,@(production-site-tasks "test" "www")))

   (role
    (name make-production-web)
    (tasks
     ,@(production-site-tasks "web" "www")))

   (role
    (name make-production-wiki)
    (tasks
     ,@(production-site-tasks "wiki")))

   (role
    (name make-staging-wiki)
    (tasks
     ,@(staging-site-tasks "wiki")))

   (role
    (name make-production-workshop)
    (tasks
     ,@(production-site-tasks "workshop" "www")))

   (role
    (name make-staging-workshop)
    (tasks
     ,@(staging-site-tasks "workshop" "www")))

   (role
    (name make-production-events)
    (tasks
     ,@(production-site-tasks "events" "www")))

   (role
    (name make-production-files)
    (tasks
     ,@(production-site-tasks "files" "www")))

   (role
    (name make-production-get)
    (tasks
     ,@(production-site-tasks "get" "www")))

   (role
    (name make-staging-get)
    (tasks
     ,@(staging-site-tasks "get" "www")))

   (role
    (name make-production-go)
    (tasks
     ,@(production-site-tasks "go" "www")
     (task
      (title "make /production/go/nginx dir")
      (file
       (path "/production/go/nginx")
       (state "directory")
       (owner "prod-go")
       (group "users")
       (mode "u=rwX,g=rwX,o=rX")
       (follow false)
       (recurse true)))
     (task
      (title "ensure /production/go/nginx/map.conf exists")
      (copy
       (dest "/production/go/nginx/map.conf")
       (content "")
       (force false)
       (owner "prod-go")
       (group "users")
       (mode "u=rwX,g=rwX,o=rX")
       (follow false)))))

   (role
    (name make-production-groups)
    (tasks
     ,@(production-site-tasks "groups" "www")))

   (role
    (name make-production-conservatory)
    (tasks
     ,@(production-site-tasks "conservatory" "www")))

   (role
    (name make-production-containers)
    (tasks
     ,@(production-site-tasks "containers" "www")))

   (role
    (name make-production-lists)
    (tasks
     ,@(production-site-tasks "lists" "www")))

   (role
    (name make-production-research)
    (tasks
     ,@(production-site-tasks "research" "www")))

   (role
    (name make-production-standards)
    (tasks
     ,@(production-site-tasks "standards" "www")))

   (role
    (name make-production-server)
    (tasks
     ,@(production-site-tasks "server" "www")))

   (role
    (name make-production-try)
    (tasks
     ,@(production-site-tasks "try" "www")))

   (role
    (name make-production-video)
    (tasks
     ,@(production-site-tasks "video" "www")))

   (role
    (name nginx)
    (tasks
     (task
      (title "install nginx and certbot")
      (apt
       (name
        ("nginx"
         "certbot"
         "python3-certbot-nginx")))
      (notify "restart nginx"))
     (task
      (title "backup system nginx.conf to nginx.conf.orig")
      (copy
       (dest "/etc/nginx/nginx.conf.orig")
       (src "/etc/nginx/nginx.conf")
       (remote-src true)
       (mode "0444")
       (force false)))
     (task
      (title "install our own nginx.conf")
      (copy
       (validate "nginx -t -c %s")
       (dest "/etc/nginx/nginx.conf")
       (src "nginx.conf")
       (owner "root")
       (group "root")
       (mode "0644"))
      (notify "restart nginx"))
     (task
      (title "start nginx now and at every boot")
      (service
       (name "nginx")
       (enabled true)
       (state "started"))))
    (handlers
     (handler
      (title "restart nginx")
      (service
       (name "nginx")
       (state "restarted")))))))
