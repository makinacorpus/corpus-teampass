{% set cfg = opts['ms_project'] %}
{% set scfg = salt['mc_utils.json_dump'](cfg)%}
{% set php = salt['mc_php.settings']() %}
{% set data = cfg.data %}

{% import "makina-states/services/php/macros.sls" as macros with context %}

include:
  - makina-states.services.php.phpfpm_with_nginx

{% for mod, ext in data.get('php_exts', {}).items() %}
{{ macros.toggle_ext(ext, True) }}
{% endfor %}

prepreqs-{{cfg.name}}:
  pkg.installed:
    - watch_in:
      - mc_proxy: makina-php-pre-inst
    - pkgs:
      - unzip
      {% for mod, ext in data.get('php_exts', {}).items() %}
      - "{{mod}}"
      {% endfor %}
      - xsltproc
      - curl
      - {{ php.packages.mysql }}
      - {{ php.packages.gd }}
      - {{ php.packages.cli }}
      - {{ php.packages.curl }}
      - {{ php.packages.ldap }}
      - {{ php.packages.dev }}
      - {{ php.packages.json }}
      - sqlite3
      - libsqlite3-dev
      - mysql-client
      - apache2-utils
      - autoconf
      - automake
      - build-essential
      - bzip2
      - gettext
      - git
      - groff
      - libbz2-dev
      - libcurl4-openssl-dev
      - libdb-dev
      - libgdbm-dev
      - libreadline-dev
      - libfreetype6-dev
      - libsigc++-2.0-dev
      - libsqlite0-dev
      - libsqlite3-dev
      - libtiff5
      - libtiff5-dev
      - libwebp5
      - libwebp-dev
      - libssl-dev
      - libtool
      - libxml2-dev
      - libxslt1-dev
      - libopenjpeg-dev
      - libopenjpeg2
      - m4
      - man-db
      - pkg-config
      - poppler-utils
      - python-dev
      - python-imaging
      - python-setuptools
      - zlib1g-dev

{{cfg.name}}-htaccess:
  file.managed:
    - name: {{data.htaccess}}
    - source: ''
    - user: www-data
    - group: www-data
    - mode: 770

{% if data.get('http_users', {}) %}
{% for userrow in data.http_users %}
{% for user, passwd in userrow.items() %}
{{cfg.name}}-{{user}}-htaccess:
  webutil.user_exists:
    - name: {{user}}
    - password: {{passwd}}
    - htpasswd_file: {{data.htaccess}}
    - options: m
    - force: true
    - watch:
      - file: {{cfg.name}}-htaccess
{% endfor %}
{% endfor %}
{% endif %}

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 770
    - watch:
      - pkg: prepreqs-{{cfg.name}}
    - names:
      - {{cfg.project_root}}/lib
      - {{cfg.project_root}}/bin
      {% if data.url_type not in ['git'] %}
      - {{cfg.data_root}}/www
      {% endif %}
      - {{cfg.data_root}}/var
      - {{cfg.data_root}}/var/log
      - {{cfg.data_root}}/var/tmp
      - {{cfg.data_root}}/var/run
      - {{cfg.data_root}}/var/private

{% for d in ['lib', 'bin'] %}
{{cfg.name}}-dirs{{d}}:
  file.symlink:
    - target: {{cfg.project_root}}/{{d}}
    - name: {{cfg.data_root}}/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
{% endfor %}

{% for d in ['var', 'www'] %}
{{cfg.name}}-l-dirs{{d}}:
  file.symlink:
    - name: {{cfg.project_root}}/{{d}}
    - target: {{cfg.data_root}}/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
{% endfor %}

{% for d in ['log', 'private', 'tmp'] %}
{{cfg.name}}-l-var-dirs{{d}}:
  file.symlink:
    - name: {{cfg.project_root}}/{{d}}
    - target: {{cfg.data_root}}/var/{{d}}
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - watch:
      - file: {{cfg.name}}-dirs
{% endfor %}
