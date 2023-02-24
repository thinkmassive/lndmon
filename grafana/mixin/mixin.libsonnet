// Prometheus Mixin
// Follows the kubernetes-mixin project pattern here: https://github.com/kubernetes-monitoring/kubernetes-mixin
// Mixin design doc: https://raw.githubusercontent.com/monitoring-mixins/docs/master/design.pdf

// This file will be imported during build for all Promethei

(import 'config.libsonnet') +
(import 'alerts/alerts.libsonnet') +
(import 'dashboards/dashboards.libsonnet') +
(import 'rules/rules.libsonnet')
