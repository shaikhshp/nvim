local status_ok, comment = pcall(require, "Comment")
if not status_ok then
  return
end

local comment_ft_ok, comment_ft = pcall(require, "Comment.ft")

local tcc_ok, ts_context_commentstring = pcall(require, "ts_context_commentstring")
if tcc_ok then
  ts_context_commentstring.setup({
    enable_autocmd = false,
  })
end

comment.setup({
  pre_hook = function(ctx)
    if comment_ft_ok then
      return comment_ft.get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
    end

    return vim.bo.commentstring
  end,
})
