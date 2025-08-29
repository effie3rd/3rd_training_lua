function fake_menu(entry)
  local m = {}
  m.entry = entry
  function m:update()
    self.entry:right()
  end
  return m
end

function fake_menu_update(menu)
  menu.entry:right()
end