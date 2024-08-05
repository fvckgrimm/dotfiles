return {
  'yamatsum/nvim-cursorline',
  opts = {
    cursorline = {
      enable = true,
      timeout = 0,
      number = true,
    },
    cursorword = {
      enable = true,
      min_length = 3,
      hl = { underline = true },
    },
  },
}
