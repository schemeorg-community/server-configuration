(ansible

 (options
  (var pipelining true))

 (groups
  (group
   (name schemeorg)
   (hosts
    (host
     (name alpha)
     (vars
      (var ansible-host "8.9.4.141")
      (var ansible-python-interpreter "/usr/bin/python3"))))))

 (playbooks

  (playbook
   (name schemeorg)
   (hosts alpha)
   (become true)
   (roles
    upgrade-packages
    set-server-basics-alpha
    set-server-basics
    configure-firewall
    install-tools
    install-nginx
    make-human-users
    make-build-user
    make-production-www
    make-staging-www
    make-production-api
    make-staging-api
    make-production-doc
    make-staging-doc
    make-production-registry
    make-production-persist
    make-production-planet
    make-production-apps
    make-production-chat
    make-production-comm
    make-production-test
    make-production-web
    make-production-events
    make-production-files
    make-production-implementations
    make-production-containers
    make-production-lists
    make-production-research
    make-production-standards
    make-production-servers
    make-production-alpha-servers
    make-production-try
    setup-lets-encrypt
    configure-nginx
    configure-ssh-server)))

 (roles

  (role
   (name upgrade-packages)
   (tasks
    (task
     (title "upgrade all apt packages to latest versions")
     (apt
      (update-cache yes)
      (upgrade "yes")))))

  (role
   (name set-server-basics-alpha)
   (tasks
    (task
     (title "set hostname")
     (hostname
      (name "alpha.servers.scheme.org")))
    (task
     (title "set purpose")
     (copy
      (dest "/etc/scheme-server-purpose")
      (content "Static web sites and redirects")))
    (task
     (title "set location")
     (copy
      (dest "/etc/scheme-server-location")
      (content "New Jersey, United States")))))

  (role
   (name set-server-basics)
   (tasks
    (task
     (title "chmod purpose file")
     (file
      (path "/etc/scheme-server-purpose")
      (owner "root")
      (group "root")
      (mode "u=r,g=r,o=r")))
    (task
     (title "chmod location file")
     (file
      (path "/etc/scheme-server-location")
      (owner "root")
      (group "root")
      (mode "u=r,g=r,o=r")))
    (task
     (title "set login greeting message")
     (copy
      (dest "/etc/motd")
      (src "files/motd")
      (owner "root")
      (group "root")
      (mode "u=rw,g=r,o=r")))
    (task
     (title "enable passwordless sudo")
     (lineinfile
      (validate "visudo -cqf /etc/sudoers")
      (path "/etc/sudoers")
      (regexp "%sudo")
      (line "%sudo ALL=(ALL:ALL) NOPASSWD:ALL")))))

  (role
   (name configure-ssh-server)
   (tasks
    (task
     (title "deny ssh root logins")
     (lineinfile
      (dest "/etc/ssh/sshd_config")
      (regexp "^#?PermitRootLogin")
      (line "PermitRootLogin no"))
     (notify "restart ssh"))
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
     (service (name "sshd") (state "restarted")))))

  (role
   (name configure-firewall)
   (tasks
    (task
     (title "install ufw")
     (apt (name "ufw")))
    (task
     (title "allow ssh")
     (ufw (rule allow) (proto tcp) (port ssh)))
    (task
     (title "allow http")
     (ufw (rule allow) (proto tcp) (port http)))
    (task
     (title "allow https")
     (ufw (rule allow) (proto tcp) (port https)))
    (task
     (title "enable firewall with default policy to deny all")
     (ufw (state enabled) (policy deny)))))

  (role
   (name install-tools)
   (tasks
    (task
     (title "text editors")
     (apt
      (name
       ("emacs"
        "mg"
        "nano"
        "vim"))))
    (task
     (title "dev tools")
     (apt
      (name
       ("build-essential"
        "git"
        "jq"
        "silversearcher-ag"))))
    (task
     (title "net tools")
     (apt
      (name
       ("dnsutils"
        "curl"
        "httpie"
        "rsync"
        "wget"))))
    (task
     (title "sys tools")
     (apt
      (name
       ("htop"
        "stow"
        "tmux"
        "tree"))))
    (task
     (title "dependencies for building gauche")
     (apt
      (name
       ("libmbedtls-dev"))))))

  (role
   (name install-nginx)
   (tasks
    (task
     (title "install nginx")
     (apt (name "nginx"))
     (notify "restart nginx"))))

  (role
   (name make-build-user)
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
   (name make-human-users)
   (tasks
    (task
     (title "make user lassi")
     (user
      (uid 1000)
      (name "lassi")
      (comment "Lassi")
      (group "users")
      (groups ("sudo"))
      (shell "/bin/bash")))
    (task
     (title "add key for lassi")
     (authorized-key
      (user "lassi")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpF8XYY5U09bxaKaXkzUaocLM3sOd2m/zptC+fIeb2S1971tIi057pZClqapfNwkCdQpPs5LJebAYlNeAK1Lhuv8PAy+6kO3zrmiyTEdz+6DmM6m6EYdGNhb1rMA5cSRb4hE72u5GdmylCzbE/YGnZuClwXeK+3g85G6CzmwRw3tFrh8r+OdiEtaaQZymFGXt0hwCVyIfGL/7eNoXgGlXq11tPp8YX3UGw2rn0GJwwD13XoWaG84S14cl4ufTFLJ+Av/QwHnEJDXcMTaPqDXIL1u+8t28QqWzdVwbhKMBjE8rzu71mg/cAW7NrEJ6PJf000B3/ATPdmtpKbFy5DCtZ lassi")))
    (task
     (title "make user arthur")
     (user
      (uid 1001)
      (name "arthur")
      (comment "Arthur")
      (group "users")
      (groups ("sudo"))
      (shell "/bin/bash")))
    (task
     (title "add key for arthur")
     (authorized-key
      (user "arthur")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAn5xABd0bK+wsy2Dl5/+GgRTTzOZP48qSPRkQHlGbnJND9IzX/W/ftYmUJFpMvxNESfFrckVbmRS70ZzbVODqeN0uvVYNdODJzGjXi5D1gib2VGNe/q5OJIyI1Z3mPhhKLEiwwbiiX1iGE4pGrmTddgYqqQW9r5TWkXRy6OqhP5s2yCcnyDlUw5x/o/JM2IQ+5wwvTTi9aOtMHwDjs/JKhKM8rRAQEMMxC0Wr410mcUIekb8PoxKQ2sCrZuxnwuH2JdBDiPqm0gpQVJVSQMgDUEegP4bf043BE62wzfXN8psNfETD9p4/94Yy4G+06n9l5fCUxmoM0jT1zRapZMthCw== arthur")))
    (task
     (title "add key for arthur")
     (authorized-key
      (user "arthur")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs6l+mUdMxwNB2bpS3tfIA8tb/UAVKndLqif5GTlS8B47awxMQQ5pwwLls697y0EdWLPxop6B9/pId51hxqdfpYcLQvHbQX+jWeEw/ZUZj0o/Ob+naDkJFHFTlMD0vrO0qKlAkWVZGJsl8PxYnUvXl0Rib9O8z2LYNKKabPDc3Z36ZBkwB2XG22TiCGbVkQudpYnPx6KYLZ31uAz8zfcIq76HPI8eyBqv6IkQeB8fPRRpHbpNSgqqnr28md8qkEe5haK5w+r1O4v8d7EcMIiYmSY7r2J45CcdCi0br0RSWpAK9HbomnknxbqfcAVioQqUTtQYwL+oulQ47DLEcGDLz arthur")))
    (task
     (title "make user hga")
     (user
      (uid 1002)
      (name "hga")
      (comment "Harold")
      (group "users")
      (groups ("sudo"))
      (shell "/bin/bash")))
    (task
     (title "add key for hga")
     (authorized-key
      (user "hga")
      (key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxF/9Gmg0vGsxasPdYWmgiN7kJGbfZfUt+hrINDQ/y/ hga")))
    (task
     (title "make user feeley")
     (user
      (uid 1003)
      (name "feeley")
      (comment "Marc")
      (group "users")
      (shell "/bin/bash")))
    (task
     (title "add key for feeley")
     (authorized-key
      (user "feeley")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA3A8iCdI/TzkcQOx2Uf4Z/kaIvVRtPTgB3d5VurlLWSmAL9akiFjKkNPIkk2VGvqTDcUOTygkIh5chtnVMhcuUvVWunOEBtrnKeFo1JLt4sg8T+EiuTqeIrjZDxKv82tAsahG6/rVVOL0sWeDydbgYX/thsHXQfOiTnhU/9PYm8s= feeley")))))

  (role
   (name make-production-doc)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9002)
      (name "prod-doc")))
    (task
     (title "make user")
     (user
      (uid 9002)
      (name "prod-doc")
      (group "prod-doc")
      (groups ("users"))
      (comment "prod-doc")
      (home "/production/doc")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/doc")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/doc")
      (state "directory")
      (owner "prod-doc")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/doc/www dir")
     (file
      (path "/production/doc/www")
      (state "directory")
      (owner "prod-doc")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/doc/log/nginx dir")
     (file
      (path "/production/doc/log/nginx")
      (state "directory")
      (owner "prod-doc")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-staging-doc)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9003)
      (name "stag-doc")))
    (task
     (title "make user")
     (user
      (uid 9003)
      (name "stag-doc")
      (group "stag-doc")
      (groups ("users"))
      (comment "stag-doc")
      (home "/staging/doc")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/staging/doc")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/staging/doc")
      (state "directory")
      (owner "stag-doc")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /staging/doc/www dir")
     (file
      (path "/staging/doc/www")
      (state "directory")
      (owner "stag-doc")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /staging/doc/log/nginx dir")
     (file
      (path "/staging/doc/log/nginx")
      (state "directory")
      (owner "stag-doc")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-www)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9004)
      (name "prod-www")))
    (task
     (title "make user")
     (user
      (uid 9004)
      (name "prod-www")
      (group "prod-www")
      (groups ("users"))
      (comment "prod-www")
      (home "/production/www")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/www")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/www")
      (state "directory")
      (owner "prod-www")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/www/www dir")
     (file
      (path "/production/www/www")
      (state "directory")
      (owner "prod-www")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/www/log/nginx dir")
     (file
      (path "/production/www/log/nginx")
      (state "directory")
      (owner "prod-www")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-staging-www)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9005)
      (name "stag-www")))
    (task
     (title "make user")
     (user
      (uid 9005)
      (name "stag-www")
      (group "stag-www")
      (groups ("users"))
      (comment "stag-www")
      (home "/staging/www")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/staging/www")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/staging/www")
      (state "directory")
      (owner "stag-www")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "add key for arthur")
     (authorized-key
      (user "stag-www")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAn5xABd0bK+wsy2Dl5/+GgRTTzOZP48qSPRkQHlGbnJND9IzX/W/ftYmUJFpMvxNESfFrckVbmRS70ZzbVODqeN0uvVYNdODJzGjXi5D1gib2VGNe/q5OJIyI1Z3mPhhKLEiwwbiiX1iGE4pGrmTddgYqqQW9r5TWkXRy6OqhP5s2yCcnyDlUw5x/o/JM2IQ+5wwvTTi9aOtMHwDjs/JKhKM8rRAQEMMxC0Wr410mcUIekb8PoxKQ2sCrZuxnwuH2JdBDiPqm0gpQVJVSQMgDUEegP4bf043BE62wzfXN8psNfETD9p4/94Yy4G+06n9l5fCUxmoM0jT1zRapZMthCw== arthur")))
    (task
     (title "add key for arthur")
     (authorized-key
      (user "stag-www")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs6l+mUdMxwNB2bpS3tfIA8tb/UAVKndLqif5GTlS8B47awxMQQ5pwwLls697y0EdWLPxop6B9/pId51hxqdfpYcLQvHbQX+jWeEw/ZUZj0o/Ob+naDkJFHFTlMD0vrO0qKlAkWVZGJsl8PxYnUvXl0Rib9O8z2LYNKKabPDc3Z36ZBkwB2XG22TiCGbVkQudpYnPx6KYLZ31uAz8zfcIq76HPI8eyBqv6IkQeB8fPRRpHbpNSgqqnr28md8qkEe5haK5w+r1O4v8d7EcMIiYmSY7r2J45CcdCi0br0RSWpAK9HbomnknxbqfcAVioQqUTtQYwL+oulQ47DLEcGDLz arthur")))
    (task
     (title "add key for lassi")
     (authorized-key
      (user "stag-www")
      (key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpF8XYY5U09bxaKaXkzUaocLM3sOd2m/zptC+fIeb2S1971tIi057pZClqapfNwkCdQpPs5LJebAYlNeAK1Lhuv8PAy+6kO3zrmiyTEdz+6DmM6m6EYdGNhb1rMA5cSRb4hE72u5GdmylCzbE/YGnZuClwXeK+3g85G6CzmwRw3tFrh8r+OdiEtaaQZymFGXt0hwCVyIfGL/7eNoXgGlXq11tPp8YX3UGw2rn0GJwwD13XoWaG84S14cl4ufTFLJ+Av/QwHnEJDXcMTaPqDXIL1u+8t28QqWzdVwbhKMBjE8rzu71mg/cAW7NrEJ6PJf000B3/ATPdmtpKbFy5DCtZ lassi")))
    (task
     (title "make /staging/www/www dir")
     (file
      (path "/staging/www/www")
      (state "directory")
      (owner "stag-www")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /staging/www/log/nginx dir")
     (file
      (path "/staging/www/log/nginx")
      (state "directory")
      (owner "stag-www")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-api)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9000)
      (name "prod-api")))
    (task
     (title "make user")
     (user
      (uid 9000)
      (name "prod-api")
      (group "prod-api")
      (comment "prod-api")
      (home "/production/api")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/api")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/api")
      (state "directory")
      (owner "prod-api")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make run script")
     (copy
      (dest "/production/api/run")
      (src "run")
      (mode "u=rwx,g=rx,o=rx"))
     #;(notify "restart services"))
    (task
     (title "make log dir")
     (file
      (path "/production/api/log")
      (state "directory")
      (owner "prod-api")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)))
    (task
     (title "make log/run script")
     (copy
      (dest "/production/api/log/run")
      (src "log-run")
      (mode "u=rwx,g=rx,o=rx"))
     #;(notify "restart services"))
    (task
     (title "make log/nginx dir")
     (file
      (path "/production/api/log/nginx")
      (state "directory")
      (owner "prod-api")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-staging-api)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9001)
      (name "stag-api")))
    (task
     (title "make user")
     (user
      (uid 9001)
      (name "stag-api")
      (group "stag-api")
      (comment "stag-api")
      (home "/staging/api")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/staging/api")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/staging/api")
      (state "directory")
      (owner "stag-api")
      (group "users")
      (follow no)
      (recurse yes)))
    #;
    (task
    (title "install packages based on package.json")
    (npm
    (path "/staging/api")))
    (task
     (title "make run script")
     (copy
      (dest "/staging/api/run")
      (src "run")
      (mode "u=rwx,g=rx,o=rx"))
     #;(notify "restart services"))
    (task
     (title "make log dir")
     (file
      (path "/staging/api/log")
      (state "directory")
      (owner "stag-api")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)))
    (task
     (title "make log/run script")
     (copy
      (dest "/staging/api/log/run")
      (src "log-run")
      (mode "u=rwx,g=rx,o=rx"))
     #;(notify "restart services"))
    (task
     (title "make log/nginx dir")
     (file
      (path "/staging/api/log/nginx")
      (state "directory")
      (owner "stag-api")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-registry)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9006)
      (name "prod-reg")))
    (task
     (title "make user")
     (user
      (uid 9006)
      (name "prod-reg")
      (group "prod-reg")
      (groups ("users"))
      (comment "prod-reg")
      (home "/production/registry")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/registry")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/registry")
      (state "directory")
      (owner "prod-reg")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/registry/www dir")
     (file
      (path "/production/registry/www")
      (state "directory")
      (owner "prod-reg")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/registry/log/nginx dir")
     (file
      (path "/production/registry/log/nginx")
      (state "directory")
      (owner "prod-reg")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-persist)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9007)
      (name "prod-persist")))
    (task
     (title "make user")
     (user
      (uid 9007)
      (name "prod-persist")
      (group "prod-persist")
      (groups ("users"))
      (comment "prod-persist")
      (home "/production/persist")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/persist")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/persist")
      (state "directory")
      (owner "prod-persist")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/persist/www dir")
     (file
      (path "/production/persist/www")
      (state "directory")
      (owner "prod-persist")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/persist/log/nginx dir")
     (file
      (path "/production/persist/log/nginx")
      (state "directory")
      (owner "prod-persist")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-planet)
   (tasks
    (task
     (title "install planet-venus")
     (apt (name "planet-venus")))
    (task
     (title "make group")
     (group
      (gid 9018)
      (name "prod-planet")))
    (task
     (title "make user")
     (user
      (uid 9018)
      (name "prod-planet")
      (group "prod-planet")
      (groups ("users"))
      (comment "prod-planet")
      (home "/production/planet")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/planet")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/planet")
      (state "directory")
      (owner "prod-planet")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/planet/www dir")
     (file
      (path "/production/planet/www")
      (state "directory")
      (owner "prod-planet")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/planet/log/nginx dir")
     (file
      (path "/production/planet/log/nginx")
      (state "directory")
      (owner "prod-planet")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "add cron job to check the feeds")
     (cron
      (name "planet")
      (job "/production/planet/planet/planet.sh")
      (user "prod-planet")
      (hour "8")
      (minute "0")))))

  (role
   (name make-production-apps)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9022)
      (name "prod-apps")))
    (task
     (title "make user")
     (user
      (uid 9022)
      (name "prod-apps")
      (group "prod-apps")
      (groups ("users"))
      (comment "prod-apps")
      (home "/production/apps")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/apps")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/apps")
      (state "directory")
      (owner "prod-apps")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/apps/www dir")
     (file
      (path "/production/apps/www")
      (state "directory")
      (owner "prod-apps")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/apps/log/nginx dir")
     (file
      (path "/production/apps/log/nginx")
      (state "directory")
      (owner "prod-apps")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-chat)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9019)
      (name "prod-chat")))
    (task
     (title "make user")
     (user
      (uid 9019)
      (name "prod-chat")
      (group "prod-chat")
      (groups ("users"))
      (comment "prod-chat")
      (home "/production/chat")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/chat")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/chat")
      (state "directory")
      (owner "prod-chat")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/chat/www dir")
     (file
      (path "/production/chat/www")
      (state "directory")
      (owner "prod-chat")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/chat/log/nginx dir")
     (file
      (path "/production/chat/log/nginx")
      (state "directory")
      (owner "prod-chat")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-comm)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9008)
      (name "prod-comm")))
    (task
     (title "make user")
     (user
      (uid 9008)
      (name "prod-comm")
      (group "prod-comm")
      (groups ("users"))
      (comment "prod-comm")
      (home "/production/comm")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/comm")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/comm")
      (state "directory")
      (owner "prod-comm")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/comm/www dir")
     (file
      (path "/production/comm/www")
      (state "directory")
      (owner "prod-comm")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/comm/log/nginx dir")
     (file
      (path "/production/comm/log/nginx")
      (state "directory")
      (owner "prod-comm")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-test)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9009)
      (name "prod-test")))
    (task
     (title "make user")
     (user
      (uid 9009)
      (name "prod-test")
      (group "prod-test")
      (groups ("users"))
      (comment "prod-test")
      (home "/production/test")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/test")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/test")
      (state "directory")
      (owner "prod-test")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/test/www dir")
     (file
      (path "/production/test/www")
      (state "directory")
      (owner "prod-test")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/test/log/nginx dir")
     (file
      (path "/production/test/log/nginx")
      (state "directory")
      (owner "prod-test")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-web)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9011)
      (name "prod-web")))
    (task
     (title "make user")
     (user
      (uid 9011)
      (name "prod-web")
      (group "prod-web")
      (groups ("users"))
      (comment "prod-web")
      (home "/production/web-topic")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/web-topic")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/web-topic")
      (state "directory")
      (owner "prod-web")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/web-topic/www dir")
     (file
      (path "/production/web-topic/www")
      (state "directory")
      (owner "prod-web")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/web-topic/log/nginx dir")
     (file
      (path "/production/web-topic/log/nginx")
      (state "directory")
      (owner "prod-web")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-events)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9016)
      (name "prod-events")))
    (task
     (title "make user")
     (user
      (uid 9016)
      (name "prod-events")
      (group "prod-events")
      (groups ("users"))
      (comment "prod-events")
      (home "/production/events")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/events")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/events")
      (state "directory")
      (owner "prod-events")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/events/www dir")
     (file
      (path "/production/events/www")
      (state "directory")
      (owner "prod-events")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/events/log/nginx dir")
     (file
      (path "/production/events/log/nginx")
      (state "directory")
      (owner "prod-events")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-files)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9013)
      (name "prod-files")))
    (task
     (title "make user")
     (user
      (uid 9013)
      (name "prod-files")
      (group "prod-files")
      (groups ("users"))
      (comment "prod-files")
      (home "/production/files")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/files")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/files")
      (state "directory")
      (owner "prod-files")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/files/www dir")
     (file
      (path "/production/files/www")
      (state "directory")
      (owner "prod-files")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/files/log/nginx dir")
     (file
      (path "/production/files/log/nginx")
      (state "directory")
      (owner "prod-files")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-implementations)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9021)
      (name "prod-impls")))
    (task
     (title "make user")
     (user
      (uid 9021)
      (name "prod-impls")
      (group "prod-impls")
      (groups ("users"))
      (comment "prod-impls")
      (home "/production/implementations")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/implementations")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/implementations")
      (state "directory")
      (owner "prod-impls")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/implementations/www dir")
     (file
      (path "/production/implementations/www")
      (state "directory")
      (owner "prod-impls")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/implementations/log/nginx dir")
     (file
      (path "/production/implementations/log/nginx")
      (state "directory")
      (owner "prod-impls")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-containers)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9020)
      (name "prod-contain")))
    (task
     (title "make user")
     (user
      (uid 9020)
      (name "prod-contain")
      (group "prod-contain")
      (groups ("users"))
      (comment "prod-contain")
      (home "/production/containers")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/containers")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/containers")
      (state "directory")
      (owner "prod-contain")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/containers/www dir")
     (file
      (path "/production/containers/www")
      (state "directory")
      (owner "prod-contain")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/containers/log/nginx dir")
     (file
      (path "/production/containers/log/nginx")
      (state "directory")
      (owner "prod-contain")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-lists)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9010)
      (name "prod-lists")))
    (task
     (title "make user")
     (user
      (uid 9010)
      (name "prod-lists")
      (group "prod-lists")
      (groups ("users"))
      (comment "prod-lists")
      (home "/production/lists")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/lists")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/lists")
      (state "directory")
      (owner "prod-lists")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/lists/www dir")
     (file
      (path "/production/lists/www")
      (state "directory")
      (owner "prod-lists")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/lists/log/nginx dir")
     (file
      (path "/production/lists/log/nginx")
      (state "directory")
      (owner "prod-lists")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-research)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9015)
      (name "prod-research")))
    (task
     (title "make user")
     (user
      (uid 9015)
      (name "prod-research")
      (group "prod-research")
      (groups ("users"))
      (comment "prod-research")
      (home "/production/research")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/research")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/research")
      (state "directory")
      (owner "prod-research")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/research/www dir")
     (file
      (path "/production/research/www")
      (state "directory")
      (owner "prod-research")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/research/log/nginx dir")
     (file
      (path "/production/research/log/nginx")
      (state "directory")
      (owner "prod-research")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-standards)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9014)
      (name "prod-standards")))
    (task
     (title "make user")
     (user
      (uid 9014)
      (name "prod-standards")
      (group "prod-standards")
      (groups ("users"))
      (comment "prod-standards")
      (home "/production/standards")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/standards")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/standards")
      (state "directory")
      (owner "prod-standards")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/standards/www dir")
     (file
      (path "/production/standards/www")
      (state "directory")
      (owner "prod-standards")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/standards/log/nginx dir")
     (file
      (path "/production/standards/log/nginx")
      (state "directory")
      (owner "prod-standards")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-servers)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9012)
      (name "prod-servers")))
    (task
     (title "make user")
     (user
      (uid 9012)
      (name "prod-servers")
      (group "prod-servers")
      (groups ("users"))
      (comment "prod-servers")
      (home "/production/servers")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/servers")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/servers")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/servers/www dir")
     (file
      (path "/production/servers/www")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/servers/log/nginx dir")
     (file
      (path "/production/servers/log/nginx")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-alpha-servers)
   ;; Re-use the prod-servers user account for this one.
   (tasks
    (task
     (title "chmod home dir")
     (file
      (path "/production/alpha.servers")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/alpha.servers")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/alpha.servers/www dir")
     (file
      (path "/production/alpha.servers/www")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/alpha.servers/log/nginx dir")
     (file
      (path "/production/alpha.servers/log/nginx")
      (state "directory")
      (owner "prod-servers")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name make-production-try)
   (tasks
    (task
     (title "make group")
     (group
      (gid 9017)
      (name "prod-try")))
    (task
     (title "make user")
     (user
      (uid 9017)
      (name "prod-try")
      (group "prod-try")
      (groups ("users"))
      (comment "prod-try")
      (home "/production/try")
      (shell "/bin/bash")
      (move-home yes)))
    (task
     (title "chmod home dir")
     (file
      (path "/production/try")
      (mode "u=rwX,g=rX,o=rX")
      (follow no)
      (recurse no)))
    (task
     (title "chown home dir")
     (file
      (path "/production/try")
      (state "directory")
      (owner "prod-try")
      (group "users")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/try/www dir")
     (file
      (path "/production/try/www")
      (state "directory")
      (owner "prod-try")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))
    (task
     (title "make /production/try/log/nginx dir")
     (file
      (path "/production/try/log/nginx")
      (state "directory")
      (owner "prod-try")
      (group "users")
      (mode "u=rwX,g=rwX,o=rX")
      (follow no)
      (recurse yes)))))

  (role
   (name setup-lets-encrypt)
   (tasks
    (task
     (title "install certbot for nginx")
     (apt
      (name
       ("certbot"
        "python-certbot-nginx"))))
    (task
     (title "add cron job for certbot renewal")
     (cron
      (name "certbot automatic renewal")
      (job "certbot renew --non-interactive --no-self-upgrade --quiet --nginx")
      (user "root")
      (hour "3")
      (minute "30")))))

  (role
   (name configure-nginx)
   (tasks
    (task
     (title "backup system nginx.conf to nginx.conf.orig")
     (copy
      (dest "/etc/nginx/nginx.conf.orig")
      (src "/etc/nginx/nginx.conf")
      (remote-src yes)
      (mode "0444")
      (force no)))
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
      (enabled yes)
      (state "started"))))
   (handlers
    (handler
     (title "restart nginx")
     (service (name "nginx") (state "restarted")))))))
