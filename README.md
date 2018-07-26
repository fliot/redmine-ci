# Redmine-ci
A redmine docker distribution, ready to serve in continuous integration workflow.

  - Full Docker image process
  - Many embeded plugins
  - Git integrally ready
  - Local repository
  - /path segregation, to easly be used behind reverse proxy/https wrapper
  - Backup-Restore process

# URL map
| Path | Description |
| ------ | ------ |
| /redmine | Redmine application |
| /git | Git repositories |

# Plugins
| Plugin | Description |
| ------ | ------ |
| Social Sign In | [https://github.com/easysoftware/redmine_social_sign_in] |
| Drawio | [https://github.com/mikitex70/redmine_drawio] |
| Mindmap | [https://www.redmine.org/plugins/mindmap-plugin] |
| Custom Workflows | [http://www.redmine.org/plugins/custom-workflows] |
| Jenkins | [https://github.com/jbox-web/redmine_jenkins] |

# Themes
| Theme | Description |
| ------ | ------ |
| Flaty Light | [https://github.com/Nitrino/flatly_light_redmine] |
| Circle | [https://www.redmineup.com/pages/themes/circle] |

# Build, Install
Edit config.sh variables, and build the docker image
```sh
$ docker build -t redmine-ci .
```

Create persistant storave volume
```sh
$ docker volume create redmine-ci_data
```

Install and run it
```sh
$ docker run -d -p 8080:80 -v /var/run/docker.sock:/var/run/docker.sock -v redmine-ci_data:/data redmine-ci
```

# TODO
- backup restore scripting
- rails rotation logs
- local git repositories
- web access of local git repositories (with redmine authentication)
- plugin redmine git (configuration)
- jenkins installation
