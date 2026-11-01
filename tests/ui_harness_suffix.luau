local function byText(text)
    for _,v in ipairs(created) do if v.Text==text then return v end end
    error('Control missing: '..text)
end
local gui=playerGui:FindFirstChild('BabftAutoBuilder');assert(gui,'GUI not created')
local window=gui:FindFirstChild('Window');assert(window and window.Size.X.Offset==366 and window.Size.Y.Offset==600)
byText('—').Activated:fire();assert(window.Visible==false and byText('BABFT').Visible==true)
byText('BABFT').Activated:fire();assert(window.Visible==true)
workspace.CurrentCamera.ViewportSize={X=844,Y=390};workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):fire()
assert(window.Size.X.Offset==500 and window.Size.Y.Offset==354 and window.Position.X.Scale==0.5 and window.Position.Y.Scale==0.5)
workspace.CurrentCamera.ViewportSize={X=390,Y=844};workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):fire()
byText('Стройка').Activated:fire();byText('Золото').Activated:fire();byText('Проверить баланс и карту').Activated:fire();assert(byText('Data.Gold: недоступен\nРазделителей этапов найдено: 0 из 10\nТриггер сундука: не найден\nЭто проверка объектов, а не проверка заработка.'));byText('Схема').Activated:fire()
byText('Загрузить и проверить JSON').Activated:fire();assert(byText('mock · блоков: 1\nТолько wood. Размер и цвет хранятся в схеме, но не применяются.'))
byText('Начать экспериментальную постройку').Activated:fire()
local found=false
for _,v in ipairs(created) do if type(v.Text)=='string' and string.find(v.Text,'Требуется явно разрешить эксперимент',1,true) then found=true end end
assert(found,'Consent gate message missing')
print('PASS mock GUI init, mobile orientation, 4 tabs, hide/reopen, mock load, consent gate')
