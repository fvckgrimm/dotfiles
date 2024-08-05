return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  opts = {
    config = {
      header = {
        ' ,-.       *,---.* __  / \\',
        " /  )    .-'       `./ /   \\",
        "(  (   ,'            `/    /|",
        " \\  `-'             \\'\\   / |",
        '  `.              ,  \\ \\ /  |',
        "   /`.          ,'-`----Y   |",
        "  (            ;        |   '",
        "  |  ,-.    ,-'         |  /",
        ' |  | (   |      grimm | /',
        ' )  | \\  `.___________|/',
        "`--'   `--'             ",
      },
      -- You can add more configuration options here
    },
  },
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}
