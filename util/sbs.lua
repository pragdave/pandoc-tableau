local processing = false
local tbl = {}

local function wl(line)
  io.stdout:write(line)
  io.stdout:write("\n")
end

local function emit_tableau(lines)
  wl("~~~ tableau")
  for i = 1, #lines do
    wl(lines[i])
  end
  wl("~~~")
end

local function emit(lines)
  wl(":::: {style='columns: 2; column-gap: 3em; column-rule: 1px solid #969; margin: 1em 0 .75em;'}")
  wl("::: {style='background: #fff2ff; padding: 0.5em 1em; break-after: column;'}")
  wl("~~~~")
  emit_tableau(lines)
  wl("~~~~")
  wl(':::')
  wl("\\columnbreak")
  emit_tableau(lines)
  wl("::::")
end

leader = "..."

for line in io.lines() do
  if processing then
    if line:find("^%s*" .. leader .. "%s*$") then
      processing = false
      emit(tbl)
      tbl = {}
    else
      table.insert(tbl, line)
    end
  else -- !processing
    s,e,leader = line:find("^%s*(:::+)%s*sbs%s*$")
    if leader then
      processing = true
    else
      wl(line)
    end
  end
end
