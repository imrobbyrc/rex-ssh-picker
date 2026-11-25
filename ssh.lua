-- ssh: "SSH: Connect…" — picker host dari ~/.ssh/config, ala git-wt.
-- Session per-host, tab idempotent: kalo udah konek, switch tab aja, gak dobel.
-- Koneksi = `ssh <host>` polos (config lu yang urus key/port/jump).
--
-- PENTING: rex.ui.pick HARUS dipanggil langsung (rex.ui.pick{...}), JANGAN
-- dibungkus pcall — pcall bikin UI-nya gak render, balikin nil diem.
-- Cancel = return (nil, "cancelled", nil), aman ditangkap biasa.
--
-- Install: require("ssh") di init.lua. Trigger: ctrl+alt+s / palette
-- "SSH: Connect Host…" / rex do ssh_open.

local M = {}

local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local SSH_CONFIG = os.getenv("HOME") .. "/.ssh/config"

-- Parse ~/.ssh/config: blok Host polos (skip pattern * ? !), ambil
-- hostname/user/port buat subtitle.
function M.list_hosts()
  local hosts, cur = {}, nil
  local f = io.open(SSH_CONFIG, "r")
  if not f then return hosts end
  for line in f:lines() do
    local key, rest = line:match("^%s*[Hh]ost%s+(.+)%s*$")
    if key then
      for pat in key:gmatch("%S+") do
        if not pat:match("[*?!]") then
          cur = { host = pat }
          hosts[#hosts + 1] = cur
        end
      end
    else
      local k, v = line:match("^%s*(%S+)%s+(.+)%s*$")
      if cur and k and v and not k:match("^#") then
        local kl = k:lower()
        if kl == "hostname" then cur.hostname = v
        elseif kl == "user" then cur.user = v
        elseif kl == "port" then cur.port = v end
      end
    end
  end
  f:close()
  return hosts
end

local function ssh_layout(host)
  return rex.layout.block{ flavor = SHELL_FLAVOR,
    options = { command = { "ssh", host }, cwd = os.getenv("HOME") } }
end

local function find_session(label)
  local ok, r = pcall(rex.call, "session.list", {})
  if not (ok and type(r) == "table") then return nil end
  for _, s in ipairs(r.sessions or {}) do
    if s.label == label then return s end
  end
  return nil
end

local function find_window(session, label)
  local ok, r = pcall(rex.call, "session.attach", { session_id = session.session_id })
  if not (ok and type(r) == "table" and r.view) then return nil end
  for _, w in ipairs(r.view.windows or {}) do
    if w.label == label then return w end
  end
  return nil
end

-- Session per-host, window per-host. Return {session_id, window_id},
-- bikin yang belum ada.
function M.open_ssh_tab(host)
  local session = find_session(host)
  if not session then
    local created = rex.call("session.create", {
      label = host,
      initial_windows = { { window_label = host, layout = ssh_layout(host) } },
    })
    return { session_id = created.session_id,
      window_id = created.initial_windows[1].window_id }
  end
  local window = find_window(session, host)
  if not window then
    window = rex.call("session.new_window", {
      session_id = session.session_id,
      window_label = host,
      layout = ssh_layout(host),
    })
  end
  return { session_id = session.session_id, window_id = window.window_id }
end

local function focus(tab)
  pcall(rex.client.queue, "session.select",
    { session_id = tab.session_id, window_id = tab.window_id })
end

rex.action{
  name = "ssh_open",
  title = "SSH: Connect Host…",
  run = function(ctx, args)
    local hosts = M.list_hosts()
    if #hosts == 0 then
      error("Gak ada host polos di " .. SSH_CONFIG, 0)
    end
    local items = {}
    for i, h in ipairs(hosts) do
      local subtitle = (h.user and (h.user .. "@") or "") .. (h.hostname or h.host)
      if h.port then subtitle = subtitle .. ":" .. h.port end
      items[#items + 1] = { id = "ssh:" .. i, title = h.host,
        subtitle = subtitle, icon = "branch" }
    end

    -- panggilan langsung — lihat catatan PENTING di atas
    local sel, why = rex.ui.pick{
      title = "SSH: Connect",
      items = items,
      placeholder = "Filter host…",
    }
    if sel == nil then return end  -- dibatalkan (why = "cancelled")

    local idx = tonumber(sel:match("^ssh:(%d+)$"))
    local h = idx and hosts[idx]
    if not h then error("pilihan gak dikenal: " .. tostring(sel), 0) end

    local tab = M.open_ssh_tab(h.host)
    focus(tab)
    return "connected: " .. h.host
  end,
}

rex.bind("ctrl+alt+s", "ssh_open")

return M
