{% from 'heat/map.jinja' import heat with context %}

include: 
    - heat.database

heat-packages:
    pkg.installed:
        - names: {{ heat.packages }}
