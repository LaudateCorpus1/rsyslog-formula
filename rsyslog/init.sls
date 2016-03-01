{% from "rsyslog/map.jinja" import rsyslog with context %}

{% if rsyslog.get('latest', False) %}
rsyslog-repo:
  pkgrepo.managed:
    - name: deb http://ppa.launchpad.net/adiscon/v8-stable/ubuntu trusty main
    - keyid: 5234BF2B
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - pkg: rsyslog
{% endif %}

rsyslog:
{% if rsyslog.get('latest', False) %}
  pkg.latest:
{% else %}
  pkg.installed:
{% endif %}
    - name: {{ rsyslog.package }}
  file.managed:
    - name: {{ rsyslog.config }}
    - template: jinja
    - source: salt://rsyslog/templates/rsyslog.conf.jinja
    - context:
      config: {{ salt['pillar.get']('rsyslog', {}) }}
  service.running:
    - enable: True
    - name: {{ rsyslog.service }}
    - require:
      - pkg: {{ rsyslog.package }}
    - watch: 
      - file: {{ rsyslog.config }}

workdirectory:
  file.directory:
    - name: {{ rsyslog.workdirectory }}
    - user: {{ rsyslog.runuser }}
    - group: {{ rsyslog.rungroup }}
    - mode: 755
    - makedirs: True

{% for filename in salt['pillar.get']('rsyslog:custom', ["50-default.conf"]) %}
{% set basename = filename.split('/')|last %}
rsyslog_custom_{{basename}}:
  file.managed:
    - name: {{ rsyslog.custom_config_path }}/{{ basename|replace(".jinja", "") }}
    {% if basename != filename %}
    - source: {{ filename }}
    {% else %}
    - source: salt://rsyslog/files/{{ filename }}
    {% endif %}
    {% if filename.endswith('.jinja') %}
    - template: jinja
    {% endif %}
    - watch_in:
      - service: {{ rsyslog.service }}
{% endfor %}
