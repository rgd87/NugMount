NugMount = CreateFrame("BUTTON","NugMount",UIParent)

NugMount:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

BINDING_HEADER_NUGMOUNT = "NugMount"
_G["BINDING_NAME_CLICK NugMount:LeftButton"] = "MountUp"
_G["BINDING_NAME_CLICK NugMount:RightButton"] = "Force Ground Mount"

NugMount:RegisterEvent("ADDON_LOADED")

local DB_VERSION = 2

local UnderwaterZones = {
    [610] = true, -- Kelp'thar Forest
    [614] = true, -- Abyssal Depths
    [615] = true, -- Shimmering Expanse
}


function NugMount.ADDON_LOADED(self,event,arg1)
    if arg1 == "NugMount" then
    
        NugMountDB = NugMountDB or {}
        if not NugMountDB.DB_VERSION or NugMountDB.DB_VERSION ~= DB_VERSION then
            table.wipe(NugMountDB)
            NugMountDB.DB_VERSION = DB_VERSION
        end
        NugMountDB.G = NugMountDB.G or {}
        NugMountDB.F = NugMountDB.F or {}
        NugMountDB.S = NugMountDB.S or {}

        local StDrv = CreateFrame("Frame",nil,nil,"SecureHandlerStateTemplate")
        StDrv:SetAttribute("_onstate-flyable",[[
            if newstate == "true"
                then self:SetAttribute("canFly", true)
                else self:SetAttribute("canFly", false)
            end
        ]])
        RegisterStateDriver(StDrv, "flyable", "[flyable] true; false");

        NugMount:SetScript("OnClick",function(self,btn)
                if IsMounted() then return Dismount() end
                -- if not initalized then self:Initialize() end
                local db = NugMountDB
                local mtype
                if btn == "RightButton" then
                    mtype = db.G
                else
                    if  next(db.S) and UnderwaterZones[GetCurrentMapAreaID()] then
                        mtype = db.S
                    elseif StDrv:GetAttribute("canFly") and next(db.F) then
                        mtype = db.F
                    else
                        mtype = db.G
                    end
                end
                if next(mtype) then
                    local spellID = NugMount:GetRandomMount(mtype)
                    NugMount:CallCompanionBySpellID(spellID)
                end
        end)
        

    elseif arg1 == "Blizzard_PetJournal" then
        for i, btn in ipairs(MountJournal.ListScrollFrame.buttons) do
            btn:SetScript("OnClick",function(self, button)
                local spellID = self.spellID
                if IsAltKeyDown() and IsControlKeyDown() then
                    if NugMountDB.S[spellID] then NugMountDB.S[spellID] = nil
                    else NugMountDB.S[spellID] = true end
                    NugMount:CheckListButton(self, spellID)
                elseif IsControlKeyDown() then
                    if NugMountDB.G[spellID] then NugMountDB.G[spellID] = nil
                    else NugMountDB.G[spellID] = true end
                    NugMount:CheckListButton(self, spellID)
                elseif IsAltKeyDown() then
                    if NugMountDB.F[spellID] then NugMountDB.F[spellID] = nil
                    else NugMountDB.F[spellID] = true end
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
        label:SetText("Alt-Click\nFlying\n\nCtrl-Click\nGround\n\nAlt+Ctrl\nSea")
        NugMount.helpLabel = label
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

function NugMount:CallCompanionBySpellID(spellID)
    local index = 1
    while true do
        local name,_,companionSpellID = GetCompanionInfo("MOUNT", index)
        if not name then return end
        if spellID == companionSpellID then return CallCompanion("MOUNT", index) end
        index = index + 1
    end
end

function NugMount:GetRandomMount(set)
    local t = {}
    for k,v in pairs(set) do
        table.insert(t,k)
    end
    local random = t[math.random(#t)]
    table.wipe(t)
    return random
end

function NugMount:CheckListButton(btn, spellID)
    local db = NugMountDB
    if db.S[spellID] then btn.sLabel:Show() else btn.sLabel:Hide() end
    if db.G[spellID] then btn.gLabel:Show() else btn.gLabel:Hide() end
    if db.F[spellID] then btn.fLabel:Show() else btn.fLabel:Hide() end
end
function NugMount.CreateLabels(self, btn)
        local size = 20
        local f = btn:CreateTexture(nil, "ARTWORK", nil, 5)
        f:SetWidth(size); f:SetHeight(size);
        f:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        f:SetTexture(GetPetTypeTexture(3)) --flying
        f:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -28, -3)

        local g = btn:CreateTexture(nil, "ARTWORK", nil, 5)
        g:SetWidth(size); g:SetHeight(size);
        g:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        g:SetTexture(GetPetTypeTexture(8)) --beast
        g:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)

        local s = btn:CreateTexture(nil, "ARTWORK", nil, 5)
        s:SetWidth(size); s:SetHeight(size);
        s:SetTexCoord(0.79687500, 0.49218750, 0.50390625, 0.65625000)
        s:SetTexture(GetPetTypeTexture(9)) --water
        s:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -53, -3)

        btn.fLabel = f
        btn.gLabel = g
        btn.sLabel = s
end









































