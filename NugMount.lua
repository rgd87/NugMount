NugMount = CreateFrame("BUTTON","NugMount",UIParent)

NugMount:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

BINDING_HEADER_NUGMOUNT = "NugMount"
_G["BINDING_NAME_CLICK NugMount:LeftButton"] = "MountUp"
_G["BINDING_NAME_CLICK NugMount:RightButton"] = "Force Ground Mount"
_G["BINDING_NAME_CLICK NugMount:MiddleButton"] = "Dismount"

NugMount:RegisterEvent("ADDON_LOADED")

local DB_VERSION = 3

local UnderwaterZones = {
    [610] = true, -- Kelp'thar Forest
    [614] = true, -- Abyssal Depths
    [615] = true, -- Shimmering Expanse
}

function NugMount.ADDON_LOADED(self,event,arg1)
    if arg1 == "NugMount" then
    
        NugMountDB = NugMountDB or {}
        if not NugMountDB.DB_VERSION or NugMountDB.DB_VERSION ~= DB_VERSION then
            if NugMountDB.DB_VERSION == 2 then -- migration from NugMount 5.0 to 5.1
                local flying = NugMountDB.F
                NugMountDB = { mounts = flying }
            else
                table.wipe(NugMountDB)
            end
            NugMountDB.DB_VERSION = DB_VERSION
        end
        NugMountDB.mounts = NugMountDB.mounts or {}
        -- NugMountDB.G = NugMountDB.G or {}
        -- NugMountDB.F = NugMountDB.F or {}
        -- NugMountDB.S = NugMountDB.S or {}
        if NugMountDB.dismount == nil then NugMountDB.dismount = true end

        local StDrv = CreateFrame("Frame",nil,nil,"SecureHandlerStateTemplate")
        StDrv:SetAttribute("_onstate-flyable",[[
            if newstate == "true"
                then self:SetAttribute("canFly", true)
                else self:SetAttribute("canFly", false)
            end
        ]])
        RegisterStateDriver(StDrv, "flyable", "[flyable] true; false");

        NugMount:SetScript("OnClick",function(self,btn)
                if IsMounted() and (NugMountDB.dismount or btn == "MiddleButton") then return Dismount() end
                -- if not initalized then self:Initialize() end
                local db = NugMountDB
                local mtype
                if btn == "RightButton" then
                    mtype = "ground"
                else
                    if  UnderwaterZones[GetCurrentMapAreaID()] then
                        mtype = "sea"
                    elseif StDrv:GetAttribute("canFly") then
                        mtype = "flying"
                    else
                        mtype = "ground"
                    end
                end
                if mtype then
                    local index = NugMount:GetRandomMount(mtype)
                    if index then CallCompanion("MOUNT", index) end
                    -- NugMount:CallCompanionBySpellID(spellID)
                end
        end)
        

    elseif arg1 == "Blizzard_PetJournal" then
        for i, btn in ipairs(MountJournal.ListScrollFrame.buttons) do
            btn:SetScript("OnClick",function(self, button)
                local spellID = self.spellID
                if IsControlKeyDown() then
                    if NugMountDB.mounts[spellID] then NugMountDB.mounts[spellID] = nil
                    else NugMountDB.mounts[spellID] = true end
                    NugMount:CheckListButton(self, spellID)
                else
                    return MountListItem_OnClick(self,button)
                end
            end)
            NugMount:CreateLabels(btn)
        end

        hooksecurefunc("MountJournal_UpdateMountList", NugMount.UpdateMountList)
        MountJournal.ListScrollFrame:HookScript("OnMouseWheel", NugMount.UpdateMountList)
        hooksecurefunc("HybridScrollFrame_Update", NugMount.UpdateMountList)
        
        local label  =  MountJournal.MountDisplay.ShadowOverlay:CreateFontString(nil, "OVERLAY")
        label:SetFontObject("GameFontNormal")
        label:SetPoint("TOPLEFT", MountJournal.MountDisplay.ShadowOverlay, "TOPLEFT",10, -10)
        label:SetJustifyH("CENTER")
        label:SetText("Ctrl-Click\nSelect favorite")
        NugMount.helpLabel = label

        NugMount:CreateCheckBox()
    end
end

function NugMount.UpdateMountList()
        --copypasted blizzard code
        local scrollFrame = MountJournal.ListScrollFrame;
        local offset = HybridScrollFrame_GetOffset(scrollFrame);
        local buttons = scrollFrame.buttons;
        local numMounts = GetNumCompanions("MOUNT");

        local showMounts = 1;
        local playerLevel = UnitLevel("player");
        if  ( numMounts < 1 ) then
            -- display the no mounts message on the right hand side
            MountJournal.MountDisplay.NoMounts:Show();
            showMounts = 0;
        else
            MountJournal.MountDisplay.NoMounts:Hide();
        end

        local numMounts = GetNumCompanions("MOUNT");
        for i=1, #buttons do
            local button = buttons[i];
            local index = i + offset;
            if ( index <= numMounts and showMounts == 1) then
                local creatureID, creatureName, spellID, icon, active = GetCompanionInfo("MOUNT", index);
                NugMount:CheckListButton(button, spellID)
            end
        end
end

-- function NugMount:CallCompanionBySpellID(spellID)
--     local index = 1
--     while true do
--         local name,_,companionSpellID = GetCompanionInfo("MOUNT", index)
--         if not name then return end
--         if spellID == companionSpellID then return CallCompanion("MOUNT", index) end
--         index = index + 1
--     end
-- end


do
    local bit_band = bit.band
    local MNT_GROUND = 0x01 -- Ground mount
    local MNT_FLYING = 0x02 -- Flying mount
    local MNT_ONWATER = 0x04 -- Usable at the water's surface
    local MNT_UNDERWATER = 0x08 -- Usable underwater
    local MNT_CANJUMP = 0x10 -- Can jump (the turtle mount cannot, for example)
    local function isMountType(mountFlags, mtype)
        if mtype == "sea" then
            return  (bit_band(mountFlags, MNT_GROUND) == 0) and
                    (bit_band(mountFlags, MNT_FLYING) == 0) and
                    (bit_band(mountFlags, MNT_UNDERWATER) == MNT_UNDERWATER)
        elseif mtype == "flying" then
            return  (bit_band(mountFlags, MNT_FLYING) == MNT_FLYING)
        elseif mtype == "ground" then
            return  (bit_band(mountFlags, MNT_GROUND) == MNT_GROUND) and
                    ((bit_band(mountFlags, MNT_CANJUMP) == MNT_CANJUMP)
                       or
                     (bit_band(mountFlags, MNT_FLYING) == 0))
        end
    end
    function NugMount:GetRandomMount(mtype, nofavs)
        local t = {}
        local favs = nofavs and {} or NugMountDB.mounts
        local index = 1
        while true do
            local creatureID, creatureName, spellID, icon, active, mountFlags = GetCompanionInfo("MOUNT", index)
            if not creatureID then break end
            if  isMountType(mountFlags, mtype) and
                ( not next(favs) or favs[spellID] )
            then
                table.insert(t, index)
            end
            index = index + 1
        end
        if not next(t) and nofavs == nil then
            return self:GetRandomMount(mtype, true)
        end
        if not next(t) and mtype ~= "ground" then
            return self:GetRandomMount("ground")
        end
        if not next(t) then return nil end

        local random = t[math.random(#t)]
        -- print(random,">>>", GetCompanionInfo("MOUNT", random))
        table.wipe(t)
        return random
    end

end


function NugMount:CheckListButton(btn, spellID)
    local db = NugMountDB
    if db.mounts[spellID] then btn.favIcon:Show() else btn.favIcon:Hide() end
end

function NugMount.CreateLabels(self, btn)
        -- local size = 20
        -- local f = btn:CreateTexture(nil, "ARTWORK", nil, 1)
        -- f:SetWidth(size); f:SetHeight(size);
        -- f:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        -- f:SetTexture(GetPetTypeTexture(3)) --flying
        -- f:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -28, -3)

        -- local g = btn:CreateTexture(nil, "ARTWORK", nil, 1)
        -- g:SetWidth(size); g:SetHeight(size);
        -- g:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        -- g:SetTexture(GetPetTypeTexture(8)) --beast
        -- g:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)

        -- local s = btn:CreateTexture(nil, "ARTWORK", nil, 1)
        -- s:SetWidth(size); s:SetHeight(size);
        -- s:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        -- s:SetTexture(GetPetTypeTexture(9)) --water
        -- s:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -53, -3)

        local fav = btn.DragButton:CreateTexture(nil, "OVERLAY", nil, 1)
        fav:SetWidth(25); fav:SetHeight(25);
        fav:SetTexCoord(0.11328125, 0.16210938, 0.02246094, 0.04687500)
        fav:SetTexture([[Interface\PetBattles\PetJournal]])
        fav:SetPoint("TOPLEFT", btn.icon, "TOPLEFT", -8, 8)

        btn.favIcon = fav
        -- btn.fLabel = f
        -- btn.gLabel = g
        -- btn.sLabel = s
end

function NugMount.CreateCheckBox(self)
    local f = CreateFrame("CheckButton",nil,MountJournal,"UICheckButtonTemplate")
    f:SetWidth(25)
    f:SetHeight(25)
    f:SetPoint("BOTTOMLEFT",MountJournal,"BOTTOMLEFT",170,2)
    f:SetChecked(NugMountDB.dismount)
    f:SetScript("OnClick",function(self,button)
        NugMountDB.dismount = not NugMountDB.dismount
    end)
    f:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("If disabled NugMount won't dismount you on the same key.", nil, nil, nil, nil, 1);
        GameTooltip:Show();
    end)
    f:SetScript("OnLeave",function(self)
        GameTooltip:Hide();
    end)
    
    local label  =  f:CreateFontString(nil, "OVERLAY")
    label:SetFontObject("GameFontNormal")
    label:SetPoint("LEFT",f,"RIGHT",0,0)
    label:SetText("Dismount")
    
    return f
end

































