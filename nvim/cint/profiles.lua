return {
  default = 'base',
  profiles = {
    base = {
      expand_on_cursor = true,
      handlers = { 'color' },
      resolve = {
        default = 'SHOW',
        precedence = { 'SHOW', 'HIGHLIGHT', 'IGNORE', 'CONCEAL' },
      },
      rules = {
        CONCEAL = {
          conceal = {
            lines = true,
          },
        },
        HIGHLIGHT = {
          highlight = true,
        },
        IGNORE = {
          ignore = {
            fg = '#555555',
          },
        },
        SHOW = false,
      },
      tags = {
        LOGGING = { meaning = 'HIGHLIGHT', bg = '#3b1c11' },
        ERROR_HANDLING = { meaning = 'HIGHLIGHT', bg = '#3d0f1f' },
        BOOKKEEPING = { meaning = 'HIGHLIGHT', bg = '#3d320f' },
        DATA_MODIFY = { meaning = 'HIGHLIGHT', bg = '#3f220d' },
        LOCAL_VALUE_MODIFY = { meaning = 'HIGHLIGHT', bg = '#293715' },
        NORMALIZATION = { meaning = 'HIGHLIGHT', bg = '#113b38' },
        SEARCH = { meaning = 'HIGHLIGHT', bg = '#0d1a3f' },
        LOOKUP = { meaning = 'HIGHLIGHT', bg = '#3d3d0f' },
        SERVICE_DELEGATION = { meaning = 'HIGHLIGHT', bg = '#2a113b' },
        SERVICE_INIT = { meaning = 'HIGHLIGHT', bg = '#0f323d' },
        BOOL_COMBINATORICS = { meaning = 'HIGHLIGHT', bg = '#113b15' },
        DATA_TRANSFORMATION = { meaning = 'HIGHLIGHT', bg = '#0f3d2a' },
        RETURN_VALUE = { meaning = 'HIGHLIGHT', bg = '#3f120d' },
        CHAINING = { meaning = 'HIGHLIGHT', bg = '#1a0d3f' },
        LOCAL_COPY = { meaning = 'HIGHLIGHT', bg = '#3b1134' },
        VALIDATION = { meaning = 'HIGHLIGHT', bg = '#1d3913' },
      },
    },
    SOFT_DISABLE = {
      extends = 'base',
      tags = {
        LOGGING = { meaning = 'SHOW' },
        ERROR_HANDLING = { meaning = 'SHOW' },
        BOOKKEEPING = { meaning = 'SHOW' },
        DATA_MODIFY = { meaning = 'SHOW' },
        LOCAL_VALUE_MODIFY = { meaning = 'SHOW' },
        NORMALIZATION = { meaning = 'SHOW' },
        SEARCH = { meaning = 'SHOW' },
        LOOKUP = { meaning = 'SHOW' },
        SERVICE_DELEGATION = { meaning = 'SHOW' },
        SERVICE_INIT = { meaning = 'SHOW' },
        BOOL_COMBINATORICS = { meaning = 'SHOW' },
        DATA_TRANSFORMATION = { meaning = 'SHOW' },
        RETURN_VALUE = { meaning = 'SHOW' },
        CHAINING = { meaning = 'SHOW' },
        LOCAL_COPY = { meaning = 'SHOW' },
        VALIDATION = { meaning = 'SHOW' },
        UNTAGGED = { meaning = 'SHOW' },
      },
    },
  },
  shards = {
    IGNORE_LOGGING = {
      tags = {
        LOGGING = { meaning = 'IGNORE' },
      },
    },
    HIDE_LOGGING = {
      tags = {
        LOGGING = { meaning = 'CONCEAL' },
      },
    },
  },
}
