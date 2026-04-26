local status_ok, comment = pcall(require, "Comment")
if not status_ok then
  return
end

local pre_hook = nil

local tcc_ok, ts_context_commentstring = pcall(require, "ts_context_commentstring")
if tcc_ok then
  ts_context_commentstring.setup({
    enable_autocmd = false,
  })

  local integration_ok, integration =
    pcall(require, "ts_context_commentstring.integrations.comment_nvim")

  if integration_ok then
    pre_hook = integration.create_pre_hook()
  end
end

comment.setup({
  pre_hook = pre_hook,
})
