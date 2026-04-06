local function writeStats(players)
    local json = "[\n"
    for i, p in ipairs(players) do
        json = json .. "  {\n"
        local entries = {}
        for k, v in pairs(p) do
            table.insert(entries, string.format('    "%s": "%s"', k, tostring(v)))
        end
        json = json .. table.concat(entries, ",\n") .. "\n  }"
        if i < #players then json = json .. "," end
        json = json .. "\n"
    end
    json = json .. "]\n"

    local filePath = os.getenv("TEMP") .. "\\PostGameStats.json"
    local file = io.open(filePath, "w")
    if file then
        file:write(json)
        file:close()
        print("[PGSM] Wrote stats to " .. filePath)
    else
        print("[PGSM] Failed to write stats file")
    end
end

RegisterHook("/Game/Prometheus/UI/OutOfGame/EndOfGame/WBP_Menu_EndOfGame.WBP_Menu_EndOfGame_C:BndEvt__WBP_Menu_EndOfGame_Tabs_K2Node_ComponentBoundEvent_2_OnActiveHeaderChanged__DelegateSignature", function(self, tabId)
    local tab = tabId:get():ToString()
    if tab ~= "stats" then return end
    print("[PGSM] Stats tab opened!")

    local rows = FindAllOf("WBP_EndOfGame_PlayerStatRow_C")
    if not rows then print("[PGSM] No rows found") return end

    local players = {}
    for _, row in ipairs(rows) do
        local ok, player = pcall(function()
            if not row.Redirects:IsValid() then return nil end
            local name = row.PlayerName:GetText():ToString()
            if name == "PlayerName" then return nil end
            name = name:gsub("<[^>]+>", "")
            local goals, assists = row.GoalsPlusAssists:GetText():ToString():match("(%d+)%+(%d+)")
            return {
                name = name,
                goals = goals or "0",
                assists = assists or "0",
                saves = row.Saves:GetText():ToString(),
                kos = row.KOs:GetText():ToString(),
                redirects = row.Redirects:GetText():ToString(),
                shots = row.Shots:GetText():ToString(),
                damage = row.Damage:GetText():ToString():gsub(",", ""),
                orbs = row.Orbs:GetText():ToString(),
            }
        end)
        if ok and player then
            table.insert(players, player)
        end
    end

    if #players > 0 then
        writeStats(players)
    else
        print("[PGSM] No valid players found")
    end
end)