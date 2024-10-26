# Configuration for Scheme.org community servers

## Scope of this document

Scheme.org involves three kinds of servers:

1. The origin server which hosts `www.scheme.org`.

2. Community servers which host consensus-driven subdomains.

3. Servers run by opinionated projects (e.g. Scheme implementations)
   to host their own stuff.

This document applies to community servers.

The origin server is run quite similarly, but is airgapped from the
community servers for reliability reasons. The social contract that
applies to the maintenance of the origin server is stricter than with
community servers.

The opinionted servers are run according to the whims of each project.
Their practices may be very different from the ones presented here.

## Machines

### VPS

Every community server is a Virtual Private Server (VPS) from a
reputable commercial host.

We deliberately use a variety of hosting providers for resilience.

### Hosting costs

Each server is paid for by an individual. Sporadic pooling of costs is
done on an infomal basis between individuals. If you are feeling
generous, donations should be made to individuals.

### Hyperscalers

We do not rent servers from the biggest players such Amazon, Google,
and Microsoft for three reasons.

1. **Values.** Scheme is a staple of the Free Software community.
Giant tech companies often act against Free Software values in
prominent ways and many people in the community are averse to them for
that reason.

2. **Complexity.** The giants offer huge and frequently changing
lineups of services and those services tend to have countless optional
features. Billing can be hard to understand. The control panels are
geared toward experts. It can take hours to figure out how to do basic
tasks.

3. **Cost.** The giants tend not to be cheaper than smaller players.

### Home servers

We do not run custom servers from people's homes and workplaces. Those
tend to have worse network connectivity than data centers, and
virtually never have the same level of reliability as a VPS.

## Operating systems

We use GNU/Linux on all servers. The reason is its popularity. With
our severely limited resources, we need something standard that every
volunteer can get around. We also need many sources to go to for help.

### Distributions

#### Debian

The only distribution we use is **Debian**. The reason is that it is
very popular and well documented. Debian is the traditional distro of
choice for Scheme and Lisp hackers. Several Scheme hackers have been
Debian Developers. Debian can be installed with one click from most
VPS providers, and the ability to change VPS providers at will is very
useful. The most popular Linux distro, Ubuntu, is based on Debian.
Debian has all the Ubuntu features we need while avoiding most of the
questionable innovations that the faster-moving Ubuntu tends to add.

#### Guix

We may add GNU Guix in the future. This will be a substantial amount
of work. The question is who will do it, and who will ensure that we
have a pool of sysadmins ready to solve the inevitable problems. Guix
has made impressive progress but it's still a new distro. After
several years our Debian installations still have sharp edges, and we
should expect Guix to have more.

## Security

### Principles

**No security by obscurity.** Everything except logs, passwords, and
private keys is considered public information that can be read by
anyone on Earth.

**Protect the outside of a server more than the inside.** We don't put
a lot of effort into limiting what sysadmins can do once they log into
a server.

**Rationale:** We are busy volunteers who tend to be programmers more
than sysadmins. We don't have the time and skill to keep up with the
latest developments in Linux and containers. Unix is structured in
such a way that it is extremely hard to isolate users from each other.
If we made an effort, it's likely that we would hinder legitimate work
while still leaving many holes. Onboarding new admins has to be a
reasonable process, and we cannot do that if everything is tweaked to
the hilt.

### Keys and passwords

SSH login is based on public keys. The keys are kept in the `keys`
subdirectory of this repository. The filename is the Unix username,
and each line is one public key.

SSH password authentication is disabled. The passwords on individual
users' Unix accounts are set to random strings. These passwords are
not intended to be used.

**Rationale:** Passwords are difficult to manage in a multi-user
environment where people come and go over the years. It is easy to
lose a password or to accidentally reveal a password. Additionally,
scripting with keys tends to be easy whereas scripting with passwords
tends to be difficult. Our configuration is highly automated.

### TLS

We get our Transport Layer Security (TLS) certificates from Let's
Encrypt. These are used for HTTPS. We may find other uses for them in
the future.

We use `certbot` with its `nginx` plugin to obtain the certs. The
certs need to be updated periodically. The Debian package of `certbot`
comes with a standard cron job that does this daily.

We have one certificate per server. This is simple, and in line with
Scheme.org's commitment to transparency. It is fine that visitors are
shown exactly which servers host which subdomains.

`certbot` currently has to be run manually whenever a subdomain is
added or removed or moved from one server to another.

## Web sites

### HTTP server

We use Nginx as our HTTP server.

* It is popular. Important so we can always find help.

* It is resource efficient. Important since we run a site with a
  high-profile domain name on low-end VPS boxes. We get a lot of
  traffic. Much of it is from automated crawlers.

* It has lots of features. A site with the scale and history of
  Scheme.org has many obscure requirements that are not readily
  apparent.

### HTTPS

All community sites are accessible via HTTPS in the usual way.

Currently `http://` URLs redirect to their `https://` equivalents.

## Email

There is currently no email service under Scheme.org.

## User IDs and TCP ports

### Humans

    1000           Human user 0
    1001           Human user 1
    1002           Human user 2

### Production sites

    4000           Production site 0
    4001           Production site 1
    4002           Production site 2

### Staging sites

    7000           Staging site 0
    7001           Staging site 1
    7002           Staging site 2
