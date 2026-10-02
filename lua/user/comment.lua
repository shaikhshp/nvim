local status_ok, comment = pcall(require, "Comment")
if not status_ok then
    return
end

local context_ok, context = pcall(require, "ts_context_commentstring")
local pre_hook
if context_ok then
    context.setup({ enable_autocmd = false })
    local integration_ok, integration = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
    if integration_ok then
        pre_hook = integration.create_pre_hook()
    end
end

comment.setup({
    pre_hook = pre_hook,
})
