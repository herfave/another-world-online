local module = {}

function module.length(st)
    local length = 0
    for _, v in st do
        length += 1
    end

    return length
end

function module.insert(st, value, pos)
    local length = module.length(st)
    pos = pos or length
    st[pos] = value
    return pos
end

function module.find(st, value)
    for i, v in st do
        if v == value then
            return i
        end
    end

    return nil
end

return module