{% if include.header %}
{% assign header = include.header %}
{% else %}
{% assign header = "###" %}
{% endif %}
Render Werf chart templates to stdout

{{ header }} Syntax

```bash
werf helm render [options]
```

{{ header }} Environments

```bash
  $WERF_SECRET_KEY  Use specified secret key to extract secrets for the deploy; recommended way to 
                    set secret key in CI-system
```

{{ header }} Options

```bash
      --dir='':
            Change to the specified directory to find werf.yaml config
      --env='':
            Use specified environment (default $WERF_DEPLOY_ENVIRONMENT)
  -h, --help=false:
            help for render
      --home-dir='':
            Use specified dir to store werf cache files and dirs (default $WERF_HOME environment 
            or ~/.werf)
      --secret-values=[]:
            Additional helm secret values
      --set=[]:
            Additional helm sets
      --set-string=[]:
            Additional helm STRING sets
      --tmp-dir='':
            Use specified dir to store tmp files and dirs (default $WERF_TMP environment or system 
            tmp dir)
      --values=[]:
            Additional helm values
```
