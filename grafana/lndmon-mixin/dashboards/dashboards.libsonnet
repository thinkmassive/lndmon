{
  grafanaDashboards+:: {
    'chain.json': (import 'chain.jsonnet'),
    'channels.json': (import 'channels.json'),
    'network.json': (import 'network.json'),
    'peers.json': (import 'peers.json'),
    'perf.json': (import 'perf.json'),
    'routing.json': (import 'routing.json'),
  },
}
