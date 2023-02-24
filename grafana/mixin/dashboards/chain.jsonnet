local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local row = grafana.row;
local panel = grafana.panel;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;

grafana.dashboard.new(
  title='Chain State',
  editable=true,
  tags=['lightning-network'],
  time_from='now-6h',
)
.addTemplate(
  template.datasource(
    name='datasource',
    query='prometheus',
    current='default',
    hide='',
    label=null,
    regex='',
    refresh='load',
  )
)
.addTemplate(
  template.new(
    name='namespace',
    datasource='$datasource',
    query='label_values(namespace)',
    label='namespace',
    refresh='load',
    sort='1',
  )
)
.addTemplate(
  template.new(
    name='node',
    datasource='$datasource',
    query='label_values(lnd_chain_block_timestamp{namespace="$namespace"}, pod)',
    label='node',
    refresh='load',
    sort='1',
  )
)
.addPanel(
  graphPanel.new(
    title='On-Chain Wallet Balance',
    datasource='$datasource',
    pointradius=2,
    formatY1='currencyBTC',
  )
  .addTarget(
    prometheus.target(
      expr='lnd_wallet_balance_confirmed_sat{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='conf_sat',
    )
  )
  .addTarget(
    prometheus.target(
      expr='lnd_wallet_balance_unconfirmed_sat{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='unconf_sat',
    )
  ), gridPos={h: 8, w: 23, x: 0, y: 0},
)
.addPanel(
  graphPanel.new(
    title='UTXO Counts',
    datasource='$datasource',
    pointradius=2,
  )
  .addTarget(
    prometheus.target(
      expr='lnd_utxos_count_confirmed_total{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='num_conf_utxos',
    )
  )
  .addTarget(
    prometheus.target(
      expr='lnd_utxos_count_unconfirmed_total{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='num_unconf_utxos',
    )
  ), gridPos={h: 8, w: 12, x: 0, y: 8},
)
.addPanel(
  graphPanel.new(
    title='UTXO Sizes',
    datasource='$datasource',
    pointradius=2,
    formatY1='currencyBTC',
    logBase1Y=2,
  )
  .addTarget(
    prometheus.target(
      expr='lnd_utxos_sizes_avg_sat{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='avg_utxo_size_sat',
    )
  )
  .addTarget(
    prometheus.target(
      expr='lnd_utxos_sizes_max_sat{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='max_utxo_size_sat',
    )
  )
  .addTarget(
    prometheus.target(
      expr='lnd_utxos_sizes_min_sat{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='min_utxo_size_sat',
    )
  ), gridPos={h: 8, w: 12, x: 12, y: 8},
)
.addPanel(
  graphPanel.new(
    title='Block Height',
    datasource='$datasource',
    pointradius=2,
  )
  .addTarget(
    prometheus.target(
      expr='lnd_chain_block_height{namespace="$namespace",pod="$node"}',
      intervalFactor=1,
      legendFormat='block_height',
    )
  ), gridPos={h: 9, w: 12, x: 0, y: 16},
)
