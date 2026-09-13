return {
  all = { include = {}, exclude = {} },
  code = {
    include = { 'code' },
    exclude = { 'test', 'doc', 'generated', 'vendored', 'lock' },
  },
  docs = { include = { 'doc' }, exclude = {} },
  tests = { include = { 'test' }, exclude = {} },
}
