local Builder = {}
Builder.__index = Builder
function Builder.new(adapter, notify, wait)
    return setmetatable({adapter=adapter, notify=notify, wait=wait, state='idle',done=0,total=0}, Builder)
end
function Builder:emit(message) self.notify(self.state,self.done,self.total,message) end
function Builder:pause()
    if self.state == 'running' then self.state='paused'; self:emit('Пауза после текущего шага') end
end
function Builder:resume()
    if self.state == 'paused' then self.state='running'; self:emit('Продолжение') end
end
function Builder:cancel()
    if self.state == 'running' or self.state == 'paused' then self.state='cancelling'; self:emit('Отмена: ожидание текущего шага') end
end
function Builder:start(plan, interval)
    if self.state == 'running' or self.state == 'paused' or self.state == 'cancelling' then error('Предыдущий запуск ещё не завершён',0) end
    if type(plan) ~= 'table' or #plan == 0 then error('Пустой план',0) end
    if type(interval) ~= 'number' or interval ~= interval or interval < 0.2 or interval > 10 then error('Интервал: 0.2–10 секунд',0) end
    self.state='running'; self.done=0; self.total=#plan; self:emit('Запуск')
    for _, block in ipairs(plan) do
        while self.state == 'paused' do self.wait(0.1) end
        if self.state == 'cancelling' then self.state='cancelled'; self:emit('Отменено'); return end
        local callOk, placed, message = pcall(self.adapter.place,self.adapter,block)
        if not callOk or not placed then self.state='failed'; self:emit('Остановка: '..tostring(callOk and message or placed)); return end
        self.done += 1; self:emit(message or 'Шаг выполнен')
        if self.state == 'cancelling' then self.state='cancelled'; self:emit('Отменено'); return end
        if self.done < self.total then self.wait(interval) end
    end
    while self.state == 'paused' do self.wait(0.1) end
    if self.state == 'cancelling' then self.state='cancelled'; self:emit('Отменено'); return end
    self.state='completed'; self:emit('План завершён')
end
return Builder
