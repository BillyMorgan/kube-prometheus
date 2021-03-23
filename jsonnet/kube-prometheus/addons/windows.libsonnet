local windowsdashboards = import 'kubernetes-mixin/dashboards/windows.libsonnet';
local windowsrules = import 'kubernetes-mixin/rules/windows.libsonnet';

{
  values+:: {
    windowsScrapeConfig+:: {
      job_name: 'windows-exporter',
      static_configs: [
        {
          targets: [error 'must provide targets array'],
        },
      ],
    },

    grafana+:: {
      dashboards+:: windowsdashboards {
        _config: $.kubernetesControlPlane.mixin._config {
          wmiExporterSelector: 'job="' + $.values.windowsScrapeConfig.job_name + '"',
        },
      }.grafanaDashboards,
    },
  },
  kubernetesControlPlane+: {
    mixin+:: {
      prometheusRules+:: {
        groups+: windowsrules {
          _config: $.kubernetesControlPlane.mixin._config {
            wmiExporterSelector: 'job="' + $.values.windowsScrapeConfig.job_name + '"',
          },
        }.prometheusRules.groups,
      },
    },
  },
  prometheus+: {
    local p = self,
    local sc = [$.values.windowsScrapeConfig],
    prometheus+: {
      spec+: {
        additionalScrapeConfigs: {
          name: 'prometheus-' + p.config.name + '-additional-scrape-config',
          key: 'prometheus-additional.yaml',
        },
      },

    },
    windowsConfig: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'prometheus-' + p.config.name + '-additional-scrape-config',
        namespace: p.config.namespace,
      },
      stringData: {
        'prometheus-additional.yaml': std.manifestYamlDoc(sc),
      },
    },
  },
}
