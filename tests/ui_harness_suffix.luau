local function byText(text)
    for _,v in ipairs(created) do if v.Text==text then return v end end
    error('Control missing: '..text)
end
local gui=playerGui:FindFirstChild('BabftAutoBuilder');assert(gui,'GUI not created')
local window=gui:FindFirstChild('Window');assert(window and window.Size.X.Offset==370 and window.Size.Y.Offset==570)
byText('—').Activated:fire();assert(window.Visible==false and byText('BABFT').Visible==true)
byText('BABFT').Activated:fire();assert(window.Visible==true)
byText('Постройка').Activated:fire();byText('Схема').Activated:fire()
byText('Загрузить и проверить JSON').Activated:fire();assert(byText('mock · блоков: 1\nТолько wood. Размер и цвет хранятся в схеме, но не применяются.'))
byText('Начать экспериментальную постройку').Activated:fire()
local found=false
for _,v in ipairs(created) do if type(v.Text)=='string' and string.find(v.Text,'Требуется явно разрешить эксперимент',1,true) then found=true end end
assert(found,'Consent gate message missing')
print('PASS mock GUI init, mobile size, tabs, hide/reopen, mock load, consent gate')
