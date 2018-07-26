# Redmine-ci
A redmine docker distribution, ready to serve in continuous integration workflow.

  - Full Docker image process
  - Persistant storage
  - Many embeded plugins
  - Git integrally ready (remote and local repositories)
  - Git commit messages can be attached to redmine issues
  - Git HTTP access of local git repositories, using redmine authentication
  - Continuous integration with Jenkins
  - /path segregation, to easly be used behind reverse proxy/https wrapper
  - Backup-Restore process

# URL map
| Path | Description |
| ------ | ------ |
| /redmine | Redmine application |
| /git | Git repositories |

# Redmine Plugins
| Plugin | Description |
| ------ | ------ |
| Custom Workflows | [http://www.redmine.org/plugins/custom-workflows] |
| Drawio | [https://github.com/mikitex70/redmine_drawio] |
| Git | [https://github.com/martin-denizet/redmine_create_git] |
| Git Remote | [https://github.com/dergachev/redmine_git_remote] |
| Jenkins | [https://github.com/jbox-web/redmine_jenkins] |
| Mindmap | [https://www.redmine.org/plugins/mindmap-plugin] |
| Social Sign In | [https://github.com/easysoftware/redmine_social_sign_in] |


# Redmine Themes
| Theme | Description |
| ------ | ------ |
| Circle | [https://www.redmineup.com/pages/themes/circle] |
| Flaty Light | [https://github.com/Nitrino/flatly_light_redmine] |

# Jenkins Plugins
| Theme | Description |
| ------ | ------ |
| Redmine | [https://github.com/jenkinsci/redmine-plugin] |

# Build, Install
Edit config.sh variables, and build the docker image
```sh
$ docker build -t redmine-ci .
```

Create persistant storage volume
```sh
$ docker volume create redmine-ci_data
```

Install and run it
```sh
$ docker run -d -p 8080:80 -v /var/run/docker.sock:/var/run/docker.sock -v redmine-ci_data:/data redmine-ci
```

Create a local git repository (manually)
```sh
redmine-ci$ cd /opt
redmine-ci$ sh ./git-init.sh myproject

Local path (to configure to local redmine instance):
  /data/git/test2

Remote path:
  http://172.17.0.3:80/git/test2
```

Create a local git repository ("Quick create" functionnality),
Just use the GUI ;-)

Git commit messages, can be attached to Redmine issues, simply create an hook
In /data/git/yourrepository/hooks/commit-msg (with "chmod +x")
```sh
#!/usr/bin/env ruby
message_file = ARGV[0]
message = File.read(message_file)

$regex = /(refs #(\d+)|fixes #(\d+))/

if !$regex.match(message)
  puts "Your message is not formatted correctly (missing refs #XXX or fixes #XXX)"
  exit 1
end
```

# TODO
  - Backup restore scripting
  - Apache/Mysql/Rails rotation logs
  - Jenkins installation
  - Jenkins reports are stored and visible in redmine
