{
  prometheusAlerts+:: {
    groups+: [
      {
        #name: 'kubernetes-resources',
        #rules: [
        #  {
        #    alert: 'KubeNodeNotReady',
        #    expr: |||
        #      kube_node_status_condition{%(kubeStateMetricsSelector)s,condition="Ready",status="true"} == 0
        #    ||| % $._config,
        #    labels: {
        #      severity: 'warning',
        #    },
        #    annotations: {
        #      description: '{{ $labels.node }} has been unready for more than 15 minutes.',
        #      summary: 'Node is not ready.',
        #    },
        #    'for': '15m',
        #  },
        #],
      },
    ],
  }, 
}
