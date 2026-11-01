local Loader = {}
function Loader.validateUrl(url)
    if type(url) ~= 'string' or #url > 2048 then error('Неверный URL', 0) end
    local path = url:match('^https://raw%.githubusercontent%.com/([%w%._%-%/]+)$')
    if not path or path:find('//',1,true) or path:find('..',1,true) then error('Нужен GitHub Raw HTTPS URL без параметров и кодирования',0) end
    local segments = 0
    for _ in path:gmatch('[^/]+') do segments += 1 end
    if segments < 4 or path:sub(-1) == '/' then error('В URL нужны owner/repo/ref/путь',0) end
    return url
end
function Loader.load(url, get, decode, schema)
    Loader.validateUrl(url)
    local ok, body = pcall(get,url)
    if not ok then error('Ошибка загрузки: '..tostring(body),0) end
    return schema.parse(body,decode)
end
return Loader
