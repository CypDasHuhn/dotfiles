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
        BOOKKEEPING = {
          bg = '#442C00',
          meaning = 'HIGHLIGHT',
        },
        ERROR_HANDLING = {
          bg = '#49003B',
          meaning = 'HIGHLIGHT',
          priority = 50,
        },
        LOGGING = {
          meaning = 'HIGHLIGHT',
          bg = '#2A4C00',
          priority = 10,
        },
        UNTAGGED = {
          meaning = 'SHOW',
        },
        VALIDATION = {
          bg = '#473A00',
          meaning = 'HIGHLIGHT',
        },
      },
    },
  },
  shards = {
    IGNORE_LOGGING = { tags = {
      LOGGING = { meaning = 'IGNORE' },
    } },
    HIDE_LOGGING = { tags = {
      LOGGING = { meaning = 'CONCEAL' },
    } },
  },
}
