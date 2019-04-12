-- Dolgubon's Lazy Set Crafter
-- Created December 2016
-- Last Modified: December 23 2016
-- 
-- Created by Dolgubon (Joseph Heinzle)
-----------------------------------
--
--local original = d local function d() original(pcall(function() error("There's a d() at this line!") end )) end

function determineLine()
	local a, b  = pcall( function() local a = nil a = a+ 1 end) return b,  tonumber(string.match (b, "^%D*%d+%D*%d+%D*%d+%D*%d+%D*(%d+)" ))
end

local originalD = d
local function d(...)
	if GetDisplayName()=="@Dolgubon" then 
		originalD(...)
	end
end
DolgubonSetCrafter = DolgubonSetCrafter or {}

local queue

local craftedItems = {}
local function removeFromScroll()
end

local function getItemLinkFromItemId(itemId) 
	return string.format("|H0:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemId, 0, ITEMSTYLE_NONE, 0, 10000) 
end

local LazyCrafter

local LibLazyCrafting = LibStub:GetLibrary("LibLazyCrafting")
local out = DolgubonSetCrafter.out

local validityFunctions 

local shortVersions =
{
	{"Whitestrake's Retribution","Whitestrakes"},
	{"Daggerfall Covenant","Daggerfall"},
	{"Armor of the Seducer","Seducer"},
	{"Night Mother's Gaze","Night Mother's"},
	{"Twilight's Embrace", "Twilight's"},
	{"Alliance de Daguefilante", "Daguefilante"},
	{"Ordonnateur Militant","Ordonnateur"},
	{"Pacte de Cœurébène","Cœurébène"},

}

local achievements = {
	[ITEMSTYLE_AREA_DWEMER] =  1144, --Dwemer
	[ITEMSTYLE_GLASS] =  1319, --Glass
	[ITEMSTYLE_AREA_XIVKYN] =  1181, --Xivkyn
	[ITEMSTYLE_AREA_ANCIENT_ORC] =  1341, --Ancient Orc
	[ITEMSTYLE_AREA_AKAVIRI] =  1318, --Akaviri
	[ITEMSTYLE_UNDAUNTED] =  1348, --Mercenary
	[ITEMSTYLE_DEITY_MALACATH] =  1412, --Malacath
	[ITEMSTYLE_DEITY_TRINIMAC] =  1411, --Trinimac
	[ITEMSTYLE_ORG_OUTLAW] =  1417, --Outlaw
	[ITEMSTYLE_ALLIANCE_EBONHEART] =  1414, --Ebonheart
	[ITEMSTYLE_ALLIANCE_ALDMERI] = 1415, --Aldmeri
	[ITEMSTYLE_ALLIANCE_DAGGERFALL] =  1416, --Daggerfall
	[ITEMSTYLE_ORG_ABAHS_WATCH] =  1422, --Abah's Watch
	[ITEMSTYLE_ORG_THIEVES_GUILD] =  1423, --ThievesGuild
	[ITEMSTYLE_ORG_ASSASSINS] =  1424, --Assassins League
	[ITEMSTYLE_ENEMY_DROMOTHRA] =  1659, --DroMathra
	[ITEMSTYLE_DEITY_AKATOSH] =  1660, --Akatosh
	[ITEMSTYLE_ORG_DARK_BROTHERHOOD] =  1661, --Dark Brotherhood
	[ITEMSTYLE_ENEMY_MINOTAUR] =  1662, --Minotaur
	[ITEMSTYLE_RAIDS_CRAGLORN] =  1714, --Craglorn
	[ITEMSTYLE_ENEMY_DRAUGR] =  1715, --Draugr
	[ITEMSTYLE_AREA_YOKUDAN] =  1713, --Yokudan
	[ITEMSTYLE_HOLIDAY_HOLLOWJACK] =  1545, --Hallowjack
	[ITEMSTYLE_HOLIDAY_SKINCHANGER] =  1676, --Skinchanger
	[ITEMSTYLE_EBONY] =  1798, --Ebony
	[ITEMSTYLE_AREA_RA_GADA] =  1797, --Ra Gada
	[ITEMSTYLE_ENEMY_SILKEN_RING] = 1796, --Silken Ring
	[ITEMSTYLE_ENEMY_MAZZATUN] = 1795, --Mazzatum
	[ITEMSTYLE_ORG_MORAG_TONG] = 1933, --Morag Tong
	[ITEMSTYLE_ORG_ORDINATOR] = 1935, --Ordinator
	[ITEMSTYLE_ORG_BUOYANT_ARMIGER] = 1934, --Buoyant Armiger
	[ITEMSTYLE_AREA_ASHLANDER] = 1932, --Ashlander
	[ITEMSTYLE_ORG_REDORAN] = 2022, --Redoran
	[ITEMSTYLE_ORG_HLAALU] = 2021, --Hlaalu
	[ITEMSTYLE_ORG_TELVANNI] = 2023, --Telvanni
	[61] = 2098, --Bloodforge
	[62] = 2097, --Dreadhorn
	[65] = 2044, --Apostle
	[66] = 2045, --Ebonshadow
}
----------------------------------------------------
-- HELPER FUNCTIONS

local function StripColorAndWhitespace(text)

	text = string.gsub(text, "|c[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", "")
	text = string.gsub(text, "|r", "")
	return text
end

local function shortenNames(requestTable)

	for k,v in pairs(requestTable) do
		if type(v)=="table" then
			for i = 1, #shortVersions do

				v[2] = StripColorAndWhitespace(v[2])

				if shortVersions[i][1] == v[2] then

					v[2] = shortVersions[i][2]
				end
			end
		end
	end
end

function getNumTraitsKnown(station, pattern, trait) -- and if the trait is known
	local count = 0
	local traitKnown =false
	for i =1 ,9 do 
		if station == CRAFTING_TYPE_CLOTHIER then
			if pattern > 1 then pattern = pattern - 1 end
		end
		local traitIndex,_,known = GetSmithingResearchLineTraitInfo(station, pattern, i)
		
		if known then
			count = count + 1
		end
		
		if traitIndex == trait then
			traitKnown = known
			
		end
	end
	
	return count, traitKnown
end

function isTraitKnown(station, pattern, trait, setIndex) -- more of a router than anything. Calls getNumTraitsKnown to do the work


	trait = trait - 1
	local known, number
	if station ==CRAFTING_TYPE_WOODWORKING and pattern>1 then
		if pattern == 2 then
			number, known = getNumTraitsKnown(station, 6, trait)
		else
			number, known = getNumTraitsKnown(station, pattern -1, trait)
		end
	else
		number, known = getNumTraitsKnown(station, pattern, trait)
	end
	if trait == 0 then known = true end
	--d("Is trait known:"..tostring(known)..tostring(trait).. "with "..tostring(number).." traits known")
	return known, number>= GetSetIndexes()[setIndex][3]
end

function isStyleKnownForPattern(styleIndex, station, pattern)
	local map = -- The index of the achievement criterion to check for each pattern
	{
		[1] = {1, 10, 14, 1, 10, 14, 6, 5,3, 7, 8, 9, 12, 2},
		[2] = {5, 5,3, 7, 8, 9, 12, 2, 5,3, 7, 8, 9, 12, 2},
		[6] = {4, 13, 13, 13, 13, 11},
	}
	if IsSmithingStyleKnown(styleIndex) then return true end
	if not achievements[styleIndex] then return false end
	local _, isKnown = GetAchievementCriterion( achievements[styleIndex], map[station][pattern])
	return isKnown == 1
end

local validityFunctions = --stuff that's not here will automatically recieve a value of true.
{ -- Second value is the required parameters from the craftrequesttable needed to determine ability to craft
	["Trait"] = {function(...) local a = isTraitKnown(...) return a end , {7, 1,5, 8}},
	["Set"] = {function(...)local _,a = isTraitKnown(...) return a end , {7,1,5,8}},
	["Style"] = {isStyleKnownForPattern , {4, 7, 1}},
}



-- uses the info in validityFunctions to recheck and see if attributes are an impediment to crafting.
local function applyValidityFunctions(requestTable) 
	for attribute, table in pairs(validityFunctions) do
		if requestTable["Station"] == 7 and attribute == "Style" then
		else
			local params = {}

			for i = 1, #table[2]  do

				params[#params + 1] = requestTable["CraftRequestTable"][table[2][i]]

			end
			--d("one application for: "..attribute)
			requestTable[attribute][3] = table[1](unpack(params) )
		end
	end
end

DolgubonSetCrafter.applyValidityFunctions = applyValidityFunctions


-- Finds the material index based on the level
local function findMatIndex(level, champion)

	local index = 1

	if champion then
		index = 26
		index = index + math.floor(level/10)
	else
		index = 0
		if level<3 then
			index = 1
		else
			index = index + math.floor(level/2)
		end
	end
	return index

end

local function getPatternIndex(patternButton,weight)
	d(patternButton.selectedIndex, weight)
	--d(patternButton.selectedIndex)
	local candidate = patternButton.selectedIndex
	if weight == nil then
		-- It is a weapon
		if patternButton.selectedIndex==8 then
			-- it is a bow
			return 1, CRAFTING_TYPE_WOODWORKING
		elseif patternButton.selectedIndex==13 then
			-- it is a shield
			return 2, CRAFTING_TYPE_WOODWORKING
		elseif patternButton.selectedIndex<8 then
			-- It is metal
			return patternButton.selectedIndex , CRAFTING_TYPE_BLACKSMITHING
		else
			-- it is a staff
			return patternButton.selectedIndex - 6, CRAFTING_TYPE_WOODWORKING
			
		end
	else
		-- It is armour
		if weight == 1 then
			-- It is heavy armour
			return patternButton.selectedIndex + 7, CRAFTING_TYPE_BLACKSMITHING
		elseif weight == 2 then
			-- It is medium armour
			return patternButton.selectedIndex + 8, CRAFTING_TYPE_CLOTHIER
		else
			-- It is light armour
			if patternButton.selectedIndex==8 then
				return 2, CRAFTING_TYPE_CLOTHIER
			elseif patternButton.selectedIndex==1 then
				return 1, CRAFTING_TYPE_CLOTHIER
			else
				return patternButton.selectedIndex + 1, CRAFTING_TYPE_CLOTHIER
			end
		end

	end
end

local function addRequirements(returnedTable, addAmounts)
	DolgubonSetCrafter.materialList = DolgubonSetCrafter.materialList or {}
	local parity = -1
	if addAmounts then parity = 1 end


	local requirements = LazyCrafter:getMatRequirements(returnedTable)

	for itemId, amount in pairs(requirements) do
		local link = getItemLinkFromItemId(itemId)
		local bag, bank, craft = GetItemLinkStacks(link)
		if DolgubonSetCrafter.materialList[itemId] then
			DolgubonSetCrafter.materialList[itemId]["Amount"] = DolgubonSetCrafter.materialList[itemId]["Amount"] + amount*parity
			DolgubonSetCrafter.materialList[itemId]["Current"] = bag + bank + craft
		else
			DolgubonSetCrafter.materialList[itemId] = {["Name"] = link ,["Amount"] = amount*parity,["Current"] = bag + bank + craft }
		end
		if DolgubonSetCrafter.materialList[itemId]["Amount"] <= 0 then DolgubonSetCrafter.materialList[itemId] = nil end
	end
end

local function oneDeepCopy(t)
	local newTable = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			newTable[k] = {}
			for dk, dv in pairs(v) do
				newTable[k][dk] = dv
			end
		else
			newTable[k] = v
		end
	end
	return newTable
end


local function addPatternToQueue(patternButton,i)
	local function shallowTwoItemCopy(t)
		return {t[1],t[2]}
	end
	local comboBoxes = DolgubonSetCrafter.ComboBox
	local requestTable = {}
	
	local pattern, station  = 0, 0
	local trait = 0
	local isArmour 

	-- Weight
	if patternButton:HaveWeights() then
		requestTable["Weight"] = {DolgubonSetCrafter:GetWeight()}
	else
		requestTable["Weight"] = {nil, ""}
	end

	-- Station
	station = patternButton:GetStation()
	requestTable["Station"] = station

	-- Pattern
	pattern = patternButton:GetPattern(requestTable["Weight"][1])
	requestTable["Pattern"] = {pattern,patternButton.tooltip}

	-- Traits
	local traitTable = patternButton:TraitsToUse()
	if traitTable.invalidSelection() and not DolgubonSetCrafter.savedvars.autofill then
		out(traitTable.selectPrompt)
		return
	end
	trait = traitTable.selected[1]
	requestTable["Trait"] = {trait, traitTable.selected[2] }

	--Styles
	if patternButton:UseStyle() then
		requestTable["Style"] 	= shallowTwoItemCopy(comboBoxes.Style.selected)
		styleIndex 				= comboBoxes.Style.selected[1]
	else
		styleIndex 				= 0 
	end

	local level, isCP = DolgubonSetCrafter:GetLevel()
	
	requestTable["Level"] = {level, level} -- doubled to simplify code in other areas


	requestTable["Set"]			= shallowTwoItemCopy(comboBoxes.Set.selected)
	local setIndex 				= comboBoxes.Set.selected[1]

	requestTable["Quality"]		= shallowTwoItemCopy(comboBoxes.Quality.selected)
	local quality 				= comboBoxes.Quality.selected[1]

	-- Check that all selections are valid, i.e. valid level and not 'select trait'
	if not level then -- is a level entered?
		requestTable["Level"][1]=nil 
		out(DolgubonSetCrafterWindowInputInputBox.selectPrompt) 
		return
		-- Is the level valid?
	elseif not LazyCrafter.isSmithingLevelValid(  isCP, requestTable["Level"][1] ) then 
		out(DolgubonSetCrafter.localizedStrings.UIStrings.invalidLevel)
		return
	end
	-- Are all the combobox selections valid? We already checked traits though, so filter those out
	for k, combobox in pairs(comboBoxes) do
		if (not combobox.isTrait and combobox.invalidSelection()) and not DolgubonSetCrafter.savedvars.autofill then
			out(combobox.selectPrompt)
			return
		end
	end

	-- Some names are just so long, we need to shorten it
	shortenNames(requestTable)
	-- double checking one final time
	if pattern and isCP ~= nil and requestTable["Level"][1] and (styleIndex or station == 7) and trait and station and setIndex and quality then
		local craftMultiplier = DolgubonSetCrafter:GetMultiplier()
		craftMultiplier = math.max(math.floor(craftMultiplier), 1) -- Make it an integer, also make it minimum of 1
		for i = 1, craftMultiplier do
			-- First, create a deep(er) copy. Tables only go down one deep so that's max depth we need to copy
			local requestTableCopy = oneDeepCopy(requestTable)
			-- increment counter for unique reference
			requestTableCopy["Reference"]	= DolgubonSetCrafter.savedvars.counter
			DolgubonSetCrafter.savedvars.counter = DolgubonSetCrafter.savedvars.counter + 1

			local CraftRequestTable = {
				pattern, 
				isCP,
				tonumber(requestTableCopy["Level"][1]),
				styleIndex,
				trait, 
				DolgubonSetCrafter:GetMimicStoneUse(), 
				station,  
				setIndex, 
				quality, 
				DolgubonSetCrafter:GetAutocraft(),
				requestTableCopy["Reference"]
			}

			local returnedTable = LazyCrafter:CraftSmithingItemByLevel(unpack(CraftRequestTable))
			
			--LLC_CraftSmithingItemByLevel(self, patternIndex, isCP , level, styleIndex, traitIndex, useUniversalStyleItem, stationOverride, setIndex, quality, autocraft)
			if not DolgubonSetCrafterWindowInputToggleChampion.toggleValue then
				requestTableCopy["Level"][2] = "CP ".. requestTableCopy["Level"][2]
			end
			requestTableCopy["CraftRequestTable"] = CraftRequestTable
			applyValidityFunctions(requestTableCopy)
			if returnedTable then
				addRequirements(returnedTable, true)
			end
			if requestTableCopy then
				queue[#queue+1] = requestTableCopy
			end
		end
	end
end



function DolgubonSetCrafter.compileMatRequirements()
	out("")
	local patternButtonSelected = false
	for i = 1, #DolgubonSetCrafter.patternButtons do
		--d(DolgubonSetCrafter.patternButtons[i].tooltip..DolgubonSetCrafter.patternButtons[i].selectedIndex)
		if DolgubonSetCrafter.patternButtons[i].toggleValue then
			patternButtonSelected = true
			addPatternToQueue(DolgubonSetCrafter.patternButtons[i],i)

		end
	end
	if not patternButtonSelected then
		out(zo_strformat(DolgubonSetCrafter.localizedStrings.UIStrings.selectPrompt,DolgubonSetCrafter.localizedStrings.UIStrings.pattern))
	end
end

function DolgubonSetCrafter.craft() 

	DolgubonSetCrafter.compileMatRequirements() 
	DolgubonSetCrafter.updateList()
end


function DolgubonSetCrafter.craftConfirm()
	DolgubonSetCrafter.compileMatRequirements()
	DolgubonSetCrafterConfirm:SetHidden(false)
end

function DolgubonSetCrafter.removeFromScroll(reference, resultTable)

	local requestTable = LazyCrafter:findItemByReference(reference)[1] or resultTable

	if requestTable then 
		addRequirements(requestTable, false)
	end

	local removalFunction
	if type(reference) == "table" then
		removalFunction = reference.onClickety
		reference = reference.Reference
	end
	

	for k, v in pairs(queue) do
		if v.Reference == reference then
			table.remove(queue,k)
		end
	end
	if removalFunction then
		removalFunction()
	else
		LazyCrafter:cancelItemByReference(reference)
	end

	table.sort(queue, function(a,b) if a~=nil and b~=nil then return a["Reference"]>b["Reference"] else return b==nil end end)
	DolgubonSetCrafter.updateList()
	
end

local function LLCCraftCompleteHandler(event, station, resultTable)	
	if event ==LLC_CRAFT_SUCCESS then 
		if resultTable.type == "improvement" then resultTable.station = GetRearchLineInfoFromRetraitItem(BAG_BACKPACK, resultTable.ItemSlotID) end
		DolgubonSetCrafter.removeFromScroll(resultTable.reference, resultTable)
	elseif event == LLC_INITIAL_CRAFT_SUCCESS then

		resultTable.quality = 1
		addRequirements(resultTable , false)
		DolgubonSetCrafter.updateList()
	end
end

function DolgubonSetCrafter.clearQueue()
	for i = #queue, 1, -1 do
		DolgubonSetCrafter.removeFromScroll(queue[i].Reference)
	end

end



function DolgubonSetCrafter.initializeFunctions.initializeCrafting()
	queue = DolgubonSetCrafter.savedvars.queue

	LazyCrafter = LibLazyCrafting:AddRequestingAddon(DolgubonSetCrafter.name, false, LLCCraftCompleteHandler)
	DolgubonSetCrafter.LazyCrafter = LazyCrafter
	for k, v in pairs(queue) do 
		if not v.doNotKeep then

			local returnedTable = LazyCrafter:CraftSmithingItemByLevel(unpack(v["CraftRequestTable"]))
			addRequirements(returnedTable, true)
			if pcall(function()applyValidityFunctions(v)end) then else d("Request could not be displayed. However, you should still be able to craft it.") end
		else
			table.remove(queue, k)
		end
	end
	LazyCrafter:SetAllAutoCraft(DolgubonSetCrafter:GetSettings().autocraft)
end



local function findPatternName(pattern, station)
	local weight
	local patternName
	if station == CRAFTING_TYPE_CLOTHIER and pattern < 9 then
		weight = DolgubonSetCrafter.localizedStrings.armourTypes[3]
	elseif station == CRAFTING_TYPE_CLOTHIER then
		weight = DolgubonSetCrafter.localizedStrings.armourTypes[2]
	elseif station == CRAFTING_TYPE_BLACKSMITHING and pattern > 7 then
		weight = DolgubonSetCrafter.localizedStrings.armourTypes[1]
	else
		weight = ""
	end
	if weight ~= "" then
		if station == CRAFTING_TYPE_CLOTHIER then
			if pattern == 2 then
				patternName = DolgubonSetCrafter.localizedStrings.armourTypes[8]
			elseif pattern == 1 then
				patternName = DolgubonSetCrafter.localizedStrings.armourTypes[1]
			else
				patternName = DolgubonSetCrafter.localizedStrings.armourTypes[(pattern - 1)%7]
			end
		elseif station == CRAFTING_TYPE_BLACKSMITHING then
			patternName = DolgubonSetCrafter.localizedStrings.armourTypes[pattern%7]
		end
	elseif station == CRAFTING_TYPE_WOODWORKING then
		if pattern == 2 then
			patternName = DolgubonSetCrafter.localizedStrings.weaponNames [13]
		elseif pattern == 1 then
			patternName = DolgubonSetCrafter.localizedStrings.weaponNames [8]
		else
			patternName = DolgubonSetCrafter.localizedStrings.weaponNames [pattern + 6]
		end

	else
		patternName = DolgubonSetCrafter.localizedStrings.weaponNames[pattern]
	end
	return patternName, weight,1
end


local function findIndexName(index, table)
	for i = 1, #table do 
		if table[i][1] == index then
			return table[i][2]
		end
	end
	return ""
end


-- autocraft is ignored right now, and will automatically be true, as there is currently no set crafter support for non autocraft
-- The function will return a reference that can be used to find the craft request again.
-- Test function: /script d(DolgubonSetCrafter.AddSmithingRequest(1, true, 10, 5, 7, false, 6, 1, 1, true))
local function AddForiegnSmithingRequest(pattern, isCP, level, styleIndex, traitIndex, useUniversalStyleItem, station, setIndex, quality, autocraft, reference, craftingObject)

	local queueTable = {}
	if pattern and isCP ~= nil and level and styleIndex and traitIndex and station and setIndex and quality then

		queueTable.personalReference 					= reference
		if reference == nil then reference = DolgubonSetCrafter.savedvars.counter end
		queueTable.Reference 							= DolgubonSetCrafter.savedvars.counter
		DolgubonSetCrafter.savedvars.counter 			= DolgubonSetCrafter.savedvars.counter + 1
		queueTable.CraftRequestTable 					= {pattern, isCP,level ,styleIndex,traitIndex, useUniversalStyleItem, station,  setIndex, quality, true, reference}

		craftingObject:CraftSmithingItemByLevel(
			queueTable.CraftRequestTable[1],
			queueTable.CraftRequestTable[2],
			queueTable.CraftRequestTable[3],
			queueTable.CraftRequestTable[4],
			queueTable.CraftRequestTable[5],
			queueTable.CraftRequestTable[6],
			queueTable.CraftRequestTable[7],
			queueTable.CraftRequestTable[8],
			queueTable.CraftRequestTable[9],
			queueTable.CraftRequestTable[10],
			queueTable.CraftRequestTable[11]
			)
		local patternName, weightClassName, weightID	= findPatternName(pattern, station )
		queueTable.Pattern 								= {pattern, patternName}
		queueTable.Weight 								= {weightID, weightClassName}
		local levelName 								= tostring(level)
		if isCP then levelName 							= "CP"..levelName end
		queueTable.Level								= {level, levelName}
		queueTable.Style 								= {styleIndex, findIndexName(styleIndex, DolgubonSetCrafter.styleNames)}
		if queueTable.Weight[2] == "" then
			queueTable.Trait 							= {traitIndex, findIndexName(traitIndex, DolgubonSetCrafter.weaponTraits)}
		else
			queueTable.Trait 							= {traitIndex, findIndexName(traitIndex, DolgubonSetCrafter.armourTraits)}
		end
		queueTable.Set 									= {setIndex, findIndexName(setIndex, DolgubonSetCrafter.setIndexes)}
		queueTable.Quality 								= {quality, DolgubonSetCrafter.quality[quality][2]}
		
		--LLC_CraftSmithingItemByLevel(self, patternIndex, isCP , level, styleIndex, traitIndex, useUniversalStyleItem, stationOverride, setIndex, quality, autocraft)
		
		applyValidityFunctions(queueTable)
		queue[#queue + 1] = queueTable
	else
		d("Set Crafter: Not all required parameters were given for the public API")
	end
	DolgubonSetCrafter.updateList()
	return queueTable
end

function DolgubonSetCrafter.AddSmithingRequest(pattern, isCP, level, styleIndex, traitIndex, useUniversalStyleItem, station, setIndex, quality, autocraft)
	local t = AddForiegnSmithingRequest(pattern, isCP, level, styleIndex, traitIndex, useUniversalStyleItem, station, setIndex, quality, autocraft, nil, LazyCrafter)
	
	return t.Reference
end

function DolgubonSetCrafter.AddSmithingRequestWithReference(pattern, isCP, level, styleIndex, traitIndex, useUniversalStyleItem, station, setIndex, quality, autocraft, optionalReference, optionalCraftingObject)

	local t =AddForiegnSmithingRequest(pattern, isCP, level, styleIndex, traitIndex, useUniversalStyleItem, station, setIndex, quality, autocraf, optionalReference, optionalCraftingObject)
	t.onClickety = function() optionalCraftingObject:cancelItemByReference(optionalReference) end
	t.doNotKeep = true

end


local function slotUpdate( eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
	if isNewItem then
		--dwd(GetItemLink(bagId, slotId))
	end
end
EVENT_MANAGER:RegisterForEvent("Set Crafter", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, slotUpdate)

--[[
@Dolgubon I'd prefer getting fedback upon craft requests or what went wrong or what succeeded at a fixed line in your addon UI, 
bottom line like a status text. Having popups and tooltips everywhere is just annoying, and the click sound for each clicked entry etc. 
too btw! If you do a tooltip, please put everthing in one tooltip like Scootworks showed as example. If it's an error, colorize it red 
and/or (for the colorblinds) use an icon via zo_iconTextFormat to show it does not work.

]]


local Smithing = {}
Smithing.QUALITY = {
    [4] = "Epic"
,   [5] = "Legendary"
}

Smithing.TRAITS_WEAPON = {
    [ITEM_TRAIT_TYPE_WEAPON_POWERED    ] = { trait_name = "Powered",      trait_index = 1 }
,   [ITEM_TRAIT_TYPE_WEAPON_CHARGED    ] = { trait_name = "Charged",      trait_index = 2 }
,   [ITEM_TRAIT_TYPE_WEAPON_PRECISE    ] = { trait_name = "Precise",      trait_index = 3 }
,   [ITEM_TRAIT_TYPE_WEAPON_INFUSED    ] = { trait_name = "Infused",      trait_index = 4 }
,   [ITEM_TRAIT_TYPE_WEAPON_DEFENDING  ] = { trait_name = "Defending",    trait_index = 5 }
,   [ITEM_TRAIT_TYPE_WEAPON_TRAINING   ] = { trait_name = "Training",     trait_index = 6 }
,   [ITEM_TRAIT_TYPE_WEAPON_SHARPENED  ] = { trait_name = "Sharpened",    trait_index = 7 }
,   [ITEM_TRAIT_TYPE_WEAPON_DECISIVE   ] = { trait_name = "Decisive",     trait_index = 8 }  -- nee weighted
,   [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED  ] = { trait_name = "Nirnhoned",    trait_index = 9 }
}
Smithing.TRAITS_ARMOR    = {
    [ITEM_TRAIT_TYPE_ARMOR_STURDY      ] = { trait_name = "Sturdy",       trait_index = 1 }
,   [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = { trait_name = "Impenetrable", trait_index = 2 }
,   [ITEM_TRAIT_TYPE_ARMOR_REINFORCED  ] = { trait_name = "Reinforced",   trait_index = 3 }
,   [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED ] = { trait_name = "Well-fitted",  trait_index = 4 }
,   [ITEM_TRAIT_TYPE_ARMOR_TRAINING    ] = { trait_name = "Training",     trait_index = 5 }
,   [ITEM_TRAIT_TYPE_ARMOR_INFUSED     ] = { trait_name = "Infused",      trait_index = 6 }
,   [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS  ] = { trait_name = "Invigorating", trait_index = 7 } -- nee exploration
,   [ITEM_TRAIT_TYPE_ARMOR_DIVINES     ] = { trait_name = "Divines",      trait_index = 8 }
,   [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED   ] = { trait_name = "Nirnhoned",    trait_index = 9 }
}

Smithing.REQUEST_ITEMS = {
  [53] = { item_id = 53, item_name = "Axe",                school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  1 }
, [56] = { item_id = 56, item_name = "Mace",               school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  2 }
, [59] = { item_id = 59, item_name = "Sword",              school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  3 }
, [68] = { item_id = 68, item_name = "Greataxe",           school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  4 }
, [67] = { item_id = 67, item_name = "Greatsword",         school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  6 }
, [69] = { item_id = 69, item_name = "Maul",               school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  5 }
, [62] = { item_id = 62, item_name = "Dagger",             school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  7 }
, [46] = { item_id = 46, item_name = "Cuirass",            school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  8 }
, [50] = { item_id = 50, item_name = "Sabatons",           school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index =  9 }
, [52] = { item_id = 52, item_name = "Gauntlets",          school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index = 10 }
, [44] = { item_id = 44, item_name = "Helm",               school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index = 11 }
, [49] = { item_id = 49, item_name = "Greaves",            school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index = 12 }
, [47] = { item_id = 47, item_name = "Pauldron",           school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index = 13 }
, [48] = { item_id = 48, item_name = "Girdle",             school = CRAFTING_TYPE_BLACKSMITHING, dol_pattern_index = 14 }

, [28] = { item_id = 28, item_name = "Robe",          school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  1 }
, [ 0] = { item_id =  0, item_name = "Jerkin",        school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  2 }
, [32] = { item_id = 32, item_name = "Shoes",         school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  3 }
, [34] = { item_id = 34, item_name = "Gloves",        school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  4 }
, [26] = { item_id = 26, item_name = "Hat",           school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  5 }
, [31] = { item_id = 31, item_name = "Breeches",      school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  6 }
, [29] = { item_id = 29, item_name = "Epaulets",      school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  7 }
, [30] = { item_id = 30, item_name = "Sash",          school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  8 }

, [37] = { item_id = 37, item_name = "Jack",         school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index =  9 }
, [41] = { item_id = 41, item_name = "Boots",        school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 10 }
, [43] = { item_id = 43, item_name = "Bracers",      school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 11 }
, [35] = { item_id = 35, item_name = "Helmet",       school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 12 }
, [40] = { item_id = 40, item_name = "Guards",       school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 13 }
, [38] = { item_id = 38, item_name = "Arm Cops",     school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 14 }
, [39] = { item_id = 39, item_name = "Belt",         school = CRAFTING_TYPE_CLOTHIER, dol_pattern_index = 15 }

, [70] = { item_id = 70, item_name = "Bow",                school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  1 }
, [72] = { item_id = 72, item_name = "Inferno Staff",      school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  3 }
, [73] = { item_id = 73, item_name = "Frost Staff",        school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  4 }
, [74] = { item_id = 74, item_name = "Lightning Staff",    school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  5 }
, [71] = { item_id = 71, item_name = "Healing Staff",      school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  6 }
, [65] = { item_id = 65, item_name = "Shield",             school = CRAFTING_TYPE_WOODWORKING, dol_pattern_index =  2 }
}

Smithing.MOTIF = {
    [ITEMSTYLE_RACIAL_BRETON        ] = { mat_name = "molybdenum"          , motif_name = "Breton"               , is_simple = true } -- 01
,   [ITEMSTYLE_RACIAL_REDGUARD      ] = { mat_name = "starmetal"           , motif_name = "Redguard"             , is_simple = true } -- 02
,   [ITEMSTYLE_RACIAL_ORC           ] = { mat_name = "manganese"           , motif_name = "Orc"                  , is_simple = true } -- 03
,   [ITEMSTYLE_RACIAL_DARK_ELF      ] = { mat_name = "obsidian"            , motif_name = "Dunmer"               , is_simple = true } -- 04
,   [ITEMSTYLE_RACIAL_NORD          ] = { mat_name = "corundum"            , motif_name = "Nord"                 , is_simple = true } -- 05
,   [ITEMSTYLE_RACIAL_ARGONIAN      ] = { mat_name = "flint"               , motif_name = "Argonian"             , is_simple = true } -- 06
,   [ITEMSTYLE_RACIAL_HIGH_ELF      ] = { mat_name = "adamantite"          , motif_name = "Altmer"               , is_simple = true } -- 07
,   [ITEMSTYLE_RACIAL_WOOD_ELF      ] = { mat_name = "bone"                , motif_name = "Bosmer"               , is_simple = true } -- 08
,   [ITEMSTYLE_RACIAL_KHAJIIT       ] = { mat_name = "moonstone"           , motif_name = "Khajiit"              , is_simple = true } -- 09
,   [ITEMSTYLE_UNIQUE               ] = nil --                             , motif_name = "Unique"               } -- 10
,   [ITEMSTYLE_ORG_THIEVES_GUILD    ] = { mat_name = "fine chalk"          , motif_name = "Thieves Guild"        , pages_id  = 1423 } -- 11
,   [ITEMSTYLE_ORG_DARK_BROTHERHOOD ] = { mat_name = "black beeswax"       , motif_name = "Dark Brotherhood"     , pages_id  = 1661 } -- 12
,   [ITEMSTYLE_DEITY_MALACATH       ] = { mat_name = "potash"              , motif_name = "Malacath"             , pages_id  = 1412 } -- 13
,   [ITEMSTYLE_AREA_DWEMER          ] = { mat_name = "dwemer frame"        , motif_name = "Dwemer"               , pages_id  = 1144 } -- 14
,   [ITEMSTYLE_AREA_ANCIENT_ELF     ] = { mat_name = "palladium"           , motif_name = "Ancient Elf"          , is_simple = true } -- 15
,   [ITEMSTYLE_DEITY_AKATOSH        ] = { mat_name = "pearl sand"          , motif_name = "Order of the Hour"    , pages_id  = 1660 } -- 16
,   [ITEMSTYLE_AREA_REACH           ] = { mat_name = "copper"              , motif_name = "Barbaric"             , is_simple = true } -- 17
,   [ITEMSTYLE_ENEMY_BANDIT         ] = nil --                             , motif_name = "Bandit"               } -- 18
,   [ITEMSTYLE_ENEMY_PRIMITIVE      ] = { mat_name = "argentum"            , motif_name = "Primal"               , is_simple = true } -- 19
,   [ITEMSTYLE_ENEMY_DAEDRIC        ] = { mat_name = "daedra heart"        , motif_name = "Daedric"              , is_simple = true } -- 20
,   [ITEMSTYLE_DEITY_TRINIMAC       ] = { mat_name = "auric tusk"          , motif_name = "Trinimac"             , pages_id  = 1411 } -- 21
,   [ITEMSTYLE_AREA_ANCIENT_ORC     ] = { mat_name = "cassiterite"         , motif_name = "Ancient Orc"          , pages_id  = 1341 } -- 22
,   [ITEMSTYLE_ALLIANCE_DAGGERFALL  ] = { mat_name = "lion fang"           , motif_name = "Daggerfall Covenant"  , pages_id  = 1416 } -- 23
,   [ITEMSTYLE_ALLIANCE_EBONHEART   ] = { mat_name = "dragon scute"        , motif_name = "Ebonheart Pact"       , pages_id  = 1414 } -- 24
,   [ITEMSTYLE_ALLIANCE_ALDMERI     ] = { mat_name = "eagle feather"       , motif_name = "Aldmeri Dominion"     , pages_id  = 1415 } -- 25
,   [ITEMSTYLE_UNDAUNTED            ] = { mat_name = "laurel"              , motif_name = "Mercenary"            , pages_id  = 1348 } -- 26
,   [ITEMSTYLE_RAIDS_CRAGLORN       ] = { mat_name = "star sapphire"       , motif_name = "Celestial"            , pages_id  = 1714 } -- 27
,   [ITEMSTYLE_GLASS                ] = { mat_name = "malachite"           , motif_name = "Glass"                , pages_id  = 1319 } -- 28
,   [ITEMSTYLE_AREA_XIVKYN          ] = { mat_name = "charcoal of remorse" , motif_name = "Xivkyn"               , pages_id  = 1181 } -- 29
,   [ITEMSTYLE_AREA_SOUL_SHRIVEN    ] = { mat_name = "azure plasm"         , motif_name = "Soul-Shriven"         , is_simple = true } -- 30
,   [ITEMSTYLE_ENEMY_DRAUGR         ] = { mat_name = "pristine shroud"     , motif_name = "Draugr"               , pages_id  = 1715 } -- 31
,   [ITEMSTYLE_ENEMY_MAORMER        ] = nil --                             , motif_name = "Maormer"              } -- 32
,   [ITEMSTYLE_AREA_AKAVIRI         ] = { mat_name = "goldscale"           , motif_name = "Akaviri"              , pages_id  = 1318 } -- 33
,   [ITEMSTYLE_RACIAL_IMPERIAL      ] = { mat_name = "nickel"              , motif_name = "Imperial"             , is_simple = true } -- 34
,   [ITEMSTYLE_AREA_YOKUDAN         ] = { mat_name = "ferrous salts"       , motif_name = "Yokudan"              , pages_id  = 1713 } -- 35
,   [ITEMSTYLE_UNIVERSAL            ] = nil --                             , motif_name = "unused"               } -- 36
,   [ITEMSTYLE_AREA_REACH_WINTER    ] = nil --                             , motif_name = "Reach Winter"         } -- 37
,   [ITEMSTYLE_AREA_TSAESCI          ] = { mat_name = "snake fang"            , motif_name = "Taesci"                                  } -- 38
,   [ITEMSTYLE_ENEMY_MINOTAUR        ] = { mat_name = "oxblood fungus"        , motif_name = "Minotaur"             , pages_id  = 1662 } -- 39
,   [ITEMSTYLE_EBONY                 ] = { mat_name = "night pumice"          , motif_name = "Ebony"                , pages_id  = 1798 } -- 40
,   [ITEMSTYLE_ORG_ABAHS_WATCH       ] = { mat_name = "polished shilling"     , motif_name = "Abah's Watch"         , pages_id  = 1422 } -- 41
,   [ITEMSTYLE_HOLIDAY_SKINCHANGER   ] = { mat_name = "wolfsbane incense"     , motif_name = "Skinchanger"          , pages_id  = 1676 } -- 42
,   [ITEMSTYLE_ORG_MORAG_TONG        ] = { mat_name = "boiled carapace"       , motif_name = "Morag Tong"           , pages_id  = 1933 } -- 43
,   [ITEMSTYLE_AREA_RA_GADA          ] = { mat_name = "ancient sandstone"     , motif_name = "Ra Gada"              , pages_id  = 1797 } -- 44
,   [ITEMSTYLE_ENEMY_DROMOTHRA       ] = { mat_name = "defiled whiskers"      , motif_name = "Dro-m'Athra"          , pages_id  = 1659 } -- 45
,   [ITEMSTYLE_ORG_ASSASSINS         ] = { mat_name = "tainted blood"         , motif_name = "Assassins League"     , pages_id  = 1424 } -- 46
,   [ITEMSTYLE_ORG_OUTLAW            ] = { mat_name = "rogue's soot"          , motif_name = "Outlaw"               , pages_id  = 1417 } -- 47
,   [ITEMSTYLE_ORG_REDORAN           ] = { mat_name = "polished scarab elytra", motif_name = "Redoran"              , pages_id  = 2022 } -- 48
,   [ITEMSTYLE_ORG_HLAALU            ] = { mat_name = "refined bonemold resin", motif_name = "Hlaalu"               , pages_id  = 2021 } -- 49
,   [ITEMSTYLE_ORG_ORDINATOR         ] = { mat_name = "lustrous sphalerite"   , motif_name = "Militant Ordinator"   , pages_id  = 1935 } -- 50
,   [ITEMSTYLE_ORG_TELVANNI          ] = { mat_name = "wrought ferrofungus"   , motif_name = "Telvanni"             , pages_id  = 2023 } -- 51
,   [ITEMSTYLE_ORG_BUOYANT_ARMIGER   ] = { mat_name = "volcanic viridian"     , motif_name = "Buoyant Armiger"      , pages_id  = 1934  } -- 52
,   [ITEMSTYLE_HOLIDAY_FROSTCASTER   ] = { mat_name = "stahlrim shard"        , motif_name = "Stalhrim Frostcaster" , crown_id  = 96954 } -- 53
,   [ITEMSTYLE_AREA_ASHLANDER        ] = { mat_name = "ash canvas"            , motif_name = "Ashlander"            , pages_id  = 1932  } -- 54
,   [ITEMSTYLE_ORG_WORM_CULT   or 55 ] = { mat_name = "desecrated grave soil" , motif_name = "Worm Cult"            , pages_id  = 2120 } -- 56
,   [ITEMSTYLE_ENEMY_SILKEN_RING     ] = { mat_name = "distilled slowsilver"  , motif_name = "Silken Ring"          , pages_id  = 1796 } -- 56
,   [ITEMSTYLE_ENEMY_MAZZATUN        ] = { mat_name = "leviathan scrimshaw"   , motif_name = "Mazzatun"             , pages_id  = 1795 } -- 57
,   [ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN] = { mat_name = "grinstones"            , motif_name = "Grim Harlequin"       , crown_id  = 82039 } -- 58
,   [ITEMSTYLE_HOLIDAY_HOLLOWJACK    ] = { mat_name = "amber marble"          , motif_name = "Hollowjack"           , pages_id  = 1545 }
,   [ITEMSTYLE_BLOODFORGE      or 61 ] = { mat_name = "bloodroot flux"        , motif_name = "Bloodforge"           , pages_id  = 2098 }
,   [ITEMSTYLE_DREADHORN       or 62 ] = { mat_name = "minotaur bezoar"       , motif_name = "Dreadhorn"            , pages_id  = 2097 }
,   [ITEMSTYLE_APOSTLE         or 65 ] = { mat_name = "tempered brass"        , motif_name = "Apostle"              , pages_id  = 2044 }
,   [ITEMSTYLE_EBONSHADOW      or 66 ] = { mat_name = "tenebrous cord"        , motif_name = "Ebonshadow"           , pages_id  = 2045 }
,   [ITEMSTYLE_UNDAUNTED_67       or 67 ] = nil
,   [ITEMSTYLE_USE_ME             or 68 ] = nil
,   [ITEMSTYLE_FANG_LAIR          or 69 ] = { mat_name = "dragon bone"        , motif_name = "Fang Lair"            , pages_id  = 2190 }
,   [ITEMSTYLE_SCALECALLER        or 70 ] = { mat_name = "infected flesh"     , motif_name = "Scalecaller"          , pages_id  = 2189 }
,   [ITEMSTYLE_PSIJIC_ORDER       or 71 ] = { mat_name = "vitrified malondo"  , motif_name = "Psijic Order"         , pages_id  = 2186 }
,   [ITEMSTYLE_SAPIARCH           or 72 ] = { mat_name = "culanda lacquer"    , motif_name = "Sapiarch"             , pages_id  = 2187 }
,   [ITEMSTYLE_WELKYNAR           or 73 ] = nil
,   [ITEMSTYLE_DREMORA            or 74 ] = nil
,   [ITEMSTYLE_PYANDONEAN         or 75 ] = { mat_name = "sea serpent hide"   , motif_name = "Pyandonean"           , pages_id  = 2285 }
,   [ITEMSTYLE_DIVINE_PROSECUTION or 76 ] = nil
,   [ITEMSTYLE_MAX_VALUE             ]    = nil
}

Smithing.SET_BONUS = {
    [  1] = nil
  , [  2] = nil
  , [  3] = nil
  , [  4] = nil
  , [  5] = nil
  , [  6] = nil
  , [  7] = nil
  , [  8] = nil
  , [  9] = nil
 ,  [ 10] = nil
 ,  [ 11] = nil
 ,  [ 12] = nil
 ,  [ 13] = nil
 ,  [ 14] = nil
 ,  [ 15] = nil
 ,  [ 16] = nil
 ,  [ 17] = nil
 ,  [ 18] = nil
 ,  [ 19] = { name = "Vestments of the Warlock",                                         }
 ,  [ 20] = { name = "Witchman Armor",                                                   }
 ,  [ 21] = { name = "Akaviri Dragonguard",                                              }
 ,  [ 22] = { name = "Dreamer's Mantle",                                                 }
 ,  [ 23] = { name = "Archer's Mind",                                                    }
 ,  [ 24] = { name = "Footman's Fortune",                                                }
 ,  [ 25] = { name = "Desert Rose",                                                      }
 ,  [ 26] = { name = "Prisoner's Rags",                                                  }
 ,  [ 27] = { name = "Fiord's Legacy",                                                   }
 ,  [ 28] = { name = "Barkskin",                                                         }
 ,  [ 29] = { name = "Sergeant's Mail",                                                  }
 ,  [ 30] = { name = "Thunderbug's Carapace",                                            }
 ,  [ 31] = { name = "Silks of the Sun",                                                 }
 ,  [ 32] = { name = "Healer's Habit",                                                   }
 ,  [ 33] = { name = "Viper's Sting",                                                    }
 ,  [ 34] = { name = "Night Mother's Embrace",                                           }
 ,  [ 35] = { name = "Knightmare",                                                       }
 ,  [ 36] = { name = "Armor of the Veiled Heritance",                                    }
 ,  [ 37] = { name = "Death's Wind",                    trait_ct = 2, dol_set_index =  2 }
 ,  [ 38] = { name = "Twilight's Embrace",              trait_ct = 3, dol_set_index =  6 }
 ,  [ 39] = { name = "Alessian Order",                               }
 ,  [ 40] = { name = "Night's Silence",                 trait_ct = 2, dol_set_index =  3 }
 ,  [ 41] = { name = "Whitestrake's Retribution",       trait_ct = 4, dol_set_index = 10 }
 ,  [ 42] = nil
 ,  [ 43] = { name = "Armor of the Seducer",            trait_ct = 3, dol_set_index =  7 }
 ,  [ 44] = { name = "Vampire's Kiss",                  trait_ct = 5, dol_set_index = 11 }
 ,  [ 45] = nil
 ,  [ 46] = { name = "Noble Duelist's Silks",                                            }
 ,  [ 47] = { name = "Robes of the Withered Hand",                                       }
 ,  [ 48] = { name = "Magnus' Gift",                    trait_ct = 4, dol_set_index =  8 }
 ,  [ 49] = { name = "Shadow of the Red Mountain",                                       }
 ,  [ 50] = { name = "The Morag Tong",                                                   }
 ,  [ 51] = { name = "Night Mother's Gaze",             trait_ct = 6, dol_set_index = 14 }
 ,  [ 52] = { name = "Beckoning Steel",                                                  }
 ,  [ 53] = { name = "The Ice Furnace",                                                  }
 ,  [ 54] = { name = "Ashen Grip",                      trait_ct = 2, dol_set_index =  4 }
 ,  [ 55] = { name = "Prayer Shawl",                                                     }
 ,  [ 56] = { name = "Stendarr's Embrace",                                               }
 ,  [ 57] = { name = "Syrabane's Grip",                                                  }
 ,  [ 58] = { name = "Hide of the Werewolf",                                             }
 ,  [ 59] = { name = "Kyne's Kiss",                                                      }
 ,  [ 60] = { name = "Darkstride",                                                       }
 ,  [ 61] = { name = "Dreugh King Slayer",                                               }
 ,  [ 62] = { name = "Hatchling's Shell",                                                }
 ,  [ 63] = { name = "The Juggernaut",                                                   }
 ,  [ 64] = { name = "Shadow Dancer's Raiment",                                          }
 ,  [ 65] = { name = "Bloodthorn's Touch",                                               }
 ,  [ 66] = { name = "Robes of the Hist",                                                }
 ,  [ 67] = { name = "Shadow Walker",                                                    }
 ,  [ 68] = { name = "Stygian",                                                          }
 ,  [ 69] = { name = "Ranger's Gait",                                                    }
 ,  [ 70] = { name = "Seventh Legion Brute",                                             }
 ,  [ 71] = { name = "Durok's Bane",                                                     }
 ,  [ 72] = { name = "Nikulas' Heavy Armor",                                             }
 ,  [ 73] = { name = "Oblivion's Foe",                  trait_ct = 8, dol_set_index = 21 }
 ,  [ 74] = { name = "Spectre's Eye",                   trait_ct = 8, dol_set_index = 22 }
 ,  [ 75] = { name = "Torug's Pact",                    trait_ct = 3, dol_set_index =  5 }
 ,  [ 76] = { name = "Robes of Alteration Mastery",                                      }
 ,  [ 77] = { name = "Crusader",                                                         }
 ,  [ 78] = { name = "Hist Bark",                       trait_ct = 4, dol_set_index =  9 }
 ,  [ 79] = { name = "Willow's Path",                   trait_ct = 6, dol_set_index = 15 }
 ,  [ 80] = { name = "Hunding's Rage",                  trait_ct = 6, dol_set_index = 16 }
 ,  [ 81] = { name = "Song of Lamae",                   trait_ct = 5, dol_set_index = 12 }
 ,  [ 82] = { name = "Alessia's Bulwark",               trait_ct = 5, dol_set_index = 13 }
 ,  [ 83] = { name = "Elf Bane",                                                         }
 ,  [ 84] = { name = "Orgnum's Scales",                 trait_ct = 8, dol_set_index = 18 }
 ,  [ 85] = { name = "Almalexia's Mercy",                                                }
 ,  [ 86] = { name = "Queen's Elegance",                                                 }
 ,  [ 87] = { name = "Eyes of Mara",                    trait_ct = 8, dol_set_index = 19 }
 ,  [ 88] = { name = "Robes of Destruction Mastery",                                     }
 ,  [ 89] = { name = "Sentry",                                                           }
 ,  [ 90] = { name = "Senche's Bite",                                                    }
 ,  [ 91] = { name = "Oblivion's Edge",                                                  }
 ,  [ 92] = { name = "Kagrenac's Hope",                 trait_ct = 8, dol_set_index = 17 }
 ,  [ 93] = { name = "Storm Knight's Plate",                                             }
 ,  [ 94] = { name = "Meridia's Blessed Armor",                                          }
 ,  [ 95] = { name = "Shalidor's Curse",                trait_ct = 8, dol_set_index = 20 }
 ,  [ 96] = { name = "Armor of Truth",                                                   }
 ,  [ 97] = { name = "The Arch-Mage",                                                    }
 ,  [ 98] = { name = "Necropotence",                                                     }
 ,  [ 99] = { name = "Salvation",                                                        }
,   [100] = { name = "Hawk's Eye",                                                       }
,   [101] = { name = "Affliction",                                                       }
,   [102] = { name = "Duneripper's Scales",                                              }
,   [103] = { name = "Magicka Furnace",                                                  }
,   [104] = { name = "Curse Eater",                                                      }
,   [105] = { name = "Twin Sisters",                                                     }
,   [106] = { name = "Wilderqueen's Arch",                                               }
,   [107] = { name = "Wyrd Tree's Blessing",                                             }
,   [108] = { name = "Ravager",                                                          }
,   [109] = { name = "Light of Cyrodiil",                                                }
,   [110] = { name = "Sanctuary",                                                        }
,   [111] = { name = "Ward of Cyrodiil",                                                 }
,   [112] = { name = "Night Terror",                                                     }
,   [113] = { name = "Crest of Cyrodiil",                                                }
,   [114] = { name = "Soulshine",                                                        }
,   [115] = nil
,   [116] = { name = "The Destruction Suite",                                            }
,   [117] = { name = "Relics of the Physician, Ansur",                                   }
,   [118] = { name = "Treasures of the Earthforge",                                      }
,   [119] = { name = "Relics of the Rebellion",                                          }
,   [120] = { name = "Arms of Infernace",                                                }
,   [121] = { name = "Arms of the Ancestors",                                            }
,   [122] = { name = "Ebon Armory",                                                      }
,   [123] = { name = "Hircine's Veneer",                                                 }
,   [124] = { name = "The Worm's Raiment",                                               }
,   [125] = { name = "Wrath of the Imperium",                                            }
,   [126] = { name = "Grace of the Ancients",                                            }
,   [127] = { name = "Deadly Strike",                                                    }
,   [128] = { name = "Blessing of the Potentates",                                       }
,   [129] = { name = "Vengeance Leech",                                                  }
,   [130] = { name = "Eagle Eye",                                                        }
,   [131] = { name = "Bastion of the Heartland",                                         }
,   [132] = { name = "Shield of the Valiant",                                            }
,   [133] = { name = "Buffer of the Swift",                                              }
,   [134] = { name = "Shroud of the Lich",                                               }
,   [135] = { name = "Draugr's Heritage",                                                }
,   [136] = { name = "Immortal Warrior",                                                 }
,   [137] = { name = "Berserking Warrior",                                               }
,   [138] = { name = "Defending Warrior",                                                }
,   [139] = { name = "Wise Mage",                                                        }
,   [140] = { name = "Destructive Mage",                                                 }
,   [141] = { name = "Healing Mage",                                                     }
,   [142] = { name = "Quick Serpent",                                                    }
,   [143] = { name = "Poisonous Serpent",                                                }
,   [144] = { name = "Twice-Fanged Serpent",                                             }
,   [145] = { name = "Way of Fire",                                                      }
,   [146] = { name = "Way of Air",                                                       }
,   [147] = { name = "Way of Martial Knowledge",                                         }
,   [148] = { name = "Way of the Arena",                trait_ct = 8, dol_set_index = 23 }
,   [149] = nil
,   [150] = nil
,   [151] = nil
,   [152] = nil
,   [153] = nil
,   [154] = nil
,   [155] = { name = "Undaunted Bastion",                                                }
,   [156] = { name = "Undaunted Infiltrator",                                            }
,   [157] = { name = "Undaunted Unweaver",                                               }
,   [158] = { name = "Embershield",                                                      }
,   [159] = { name = "Sunderflame",                                                      }
,   [160] = { name = "Burning Spellweave",                                               }
,   [161] = { name = "Twice-Born Star",                 trait_ct = 9, dol_set_index = 24 }
,   [162] = { name = "Spawn of Mephala",                                                 }
,   [163] = { name = "Blood Spawn",                                                      }
,   [164] = { name = "Lord Warden",                                                      }
,   [165] = { name = "Scourge Harvester",                                                }
,   [166] = { name = "Engine Guardian",                                                  }
,   [167] = { name = "Nightflame",                                                       }
,   [168] = { name = "Nerien'eth",                                                       }
,   [169] = { name = "Valkyn Skoria",                                                    }
,   [170] = { name = "Maw of the Infernal",                                              }
,   [171] = { name = "Eternal Warrior",                                                  }
,   [172] = { name = "Infallible Mage",                                                  }
,   [173] = { name = "Vicious Serpent",                                                  }
,   [174] = nil
,   [175] = nil
,   [176] = { name = "Noble's Conquest",                trait_ct = 5, dol_set_index = 25 }
,   [177] = { name = "Redistributor",                   trait_ct = 7, dol_set_index = 26 }
,   [178] = { name = "Armor Master",                    trait_ct = 9, dol_set_index = 27 }
,   [179] = { name = "Black Rose",                                                       }
,   [180] = { name = "Powerful Assault",                                                 }
,   [181] = { name = "Meritorious Service",                                              }
,   [182] = nil
,   [183] = { name = "Molag Kena",                                                       }
,   [184] = { name = "Brands of Imperium",                                               }
,   [185] = { name = "Spell Power Cure",                                                 }
,   [186] = { name = "Jolting Arms",                                                     }
,   [187] = { name = "Swamp Raider",                                                     }
,   [188] = { name = "Storm Master",                                                     }
,   [189] = nil
,   [190] = { name = "Scathing Mage",                                                    }
,   [191] = nil
,   [192] = nil
,   [193] = { name = "Overwhelming Surge",                                               }
,   [194] = { name = "Combat Physician",                                                 }
,   [195] = { name = "Sheer Venom",                                                      }
,   [196] = { name = "Leeching Plate",                                                   }
,   [197] = { name = "Tormentor",                                                        }
,   [198] = { name = "Essence Thief",                                                    }
,   [199] = { name = "Shield Breaker",                                                   }
,   [200] = { name = "Phoenix",                                                          }
,   [201] = { name = "Reactive Armor",                                                   }
,   [202] = nil
,   [203] = nil
,   [204] = { name = "Endurance",                                                        }
,   [205] = { name = "Willpower",                                                        }
,   [206] = { name = "Agility",                                                          }
,   [207] = { name = "Law of Julianos",                 trait_ct = 6, dol_set_index = 29 }
,   [208] = { name = "Trial by Fire",                   trait_ct = 3, dol_set_index = 28 }
,   [209] = { name = "Armor of the Code",                                                }
,   [210] = { name = "Mark of the Pariah",                                               }
,   [211] = { name = "Permafrost",                                                       }
,   [212] = { name = "Briarheart",                                                       }
,   [213] = { name = "Glorious Defender",                                                }
,   [214] = { name = "Para Bellum",                                                      }
,   [215] = { name = "Elemental Succession",                                             }
,   [216] = { name = "Hunt Leader",                                                      }
,   [217] = { name = "Winterborn",                                                       }
,   [218] = { name = "Trinimac's Valor",                                                 }
,   [219] = { name = "Morkuldin",                       trait_ct = 9, dol_set_index = 30 }
,   [220] = nil
,   [221] = nil
,   [222] = nil
,   [223] = nil
,   [224] = { name = "Tava's Favor",                    trait_ct = 5, dol_set_index = 31 }
,   [225] = { name = "Clever Alchemist",                trait_ct = 7, dol_set_index = 32 }
,   [226] = { name = "Eternal Hunt",                    trait_ct = 9, dol_set_index = 33 }
,   [227] = { name = "Bahraha's Curse",                                                  }
,   [228] = { name = "Syvarra's Scales",                                                 }
,   [229] = { name = "Twilight Remedy",                                                  }
,   [230] = { name = "Moondancer",                                                       }
,   [231] = { name = "Lunar Bastion",                                                    }
,   [232] = { name = "Roar of Alkosh",                                                   }
,   [233] = nil
,   [234] = { name = "Marksman's Crest",                                                 }
,   [235] = { name = "Robes of Transmutation",                                           }
,   [236] = { name = "Vicious Death",                                                    }
,   [237] = { name = "Leki's Focus",                                                     }
,   [238] = { name = "Fasalla's Guile",                                                  }
,   [239] = { name = "Warrior's Fury",                                                   }
,   [240] = { name = "Kvatch Gladiator",                trait_ct = 6, dol_set_index = 34 }
,   [241] = { name = "Varen's Legacy",                  trait_ct = 7, dol_set_index = 35 }
,   [242] = { name = "Pelinal's Aptitude",              trait_ct = 9, dol_set_index = 36 }
,   [243] = { name = "Hide of Morihaus",                                                 }
,   [244] = { name = "Flanking Strategist",                                              }
,   [245] = { name = "Sithis' Touch",                                                    }
,   [246] = { name = "Galerion's Revenge",                                               }
,   [247] = { name = "Vicecanon of Venom",                                               }
,   [248] = { name = "Thews of the Harbinger",                                           }
,   [249] = nil
,   [250] = nil
,   [251] = nil
,   [252] = nil
,   [253] = { name = "Imperial Physique",                                                }
,   [254] = nil
,   [255] = nil
,   [256] = { name = "Mighty Chudan",                                                    }
,   [257] = { name = "Velidreth",                                                        }
,   [258] = { name = "Amber Plasm",                                                      }
,   [259] = { name = "Heem-Jas' Retribution",                                            }
,   [260] = { name = "Aspect of Mazzatun",                                               }
,   [261] = { name = "Gossamer",                                                         }
,   [262] = { name = "Widowmaker",                                                       }
,   [263] = { name = "Hand of Mephala",                                                  }
,   [264] = { name = "Giant Spider",                                                     }
,   [265] = { name = "Shadowrend",                                                       }
,   [266] = { name = "Kra'gh",                                                           }
,   [267] = { name = "Swarm Mother",                                                     }
,   [268] = { name = "Sentinel of Rkugamz",                                              }
,   [269] = { name = "Chokethorn",                                                       }
,   [270] = { name = "Slimecraw",                                                        }
,   [271] = { name = "Sellistrix",                                                       }
,   [272] = { name = "Infernal Guardian",                                                }
,   [273] = { name = "Ilambris",                                                         }
,   [274] = { name = "Iceheart",                                                         }
,   [275] = { name = "Stormfist",                                                        }
,   [276] = { name = "Tremorscale",                                                      }
,   [277] = { name = "Pirate Skeleton",                                                  }
,   [278] = { name = "The Troll King",                                                   }
,   [279] = { name = "Selene",                                                           }
,   [280] = { name = "Grothdarr",                                                        }
,   [281] = { name = "Armor of the Trainee",                                             }
,   [282] = { name = "Vampire Cloak",                                                    }
,   [283] = { name = "Sword-Singer",                                                     }
,   [284] = { name = "Order of Diagna",                                                  }
,   [285] = { name = "Vampire Lord",                                                     }
,   [286] = { name = "Spriggan's Thorns",                                                }
,   [287] = { name = "Green Pact",                                                       }
,   [288] = { name = "Beekeeper's Gear",                                                 }
,   [289] = { name = "Spinner's Garments",                                               }
,   [290] = { name = "Skooma Smuggler",                                                  }
,   [291] = { name = "Shalk Exoskeleton",                                                }
,   [292] = { name = "Mother's Sorrow",                                                  }
,   [293] = { name = "Plague Doctor",                                                    }
,   [294] = { name = "Ysgramor's Birthright",                                            }
,   [295] = { name = "Jailbreaker",                                                      }
,   [296] = { name = "Spelunker",                                                        }
,   [297] = { name = "Spider Cultist Cowl",                                              }
,   [298] = { name = "Light Speaker",                                                    }
,   [299] = { name = "Toothrow",                                                         }
,   [300] = { name = "Netch's Touch",                                                    }
,   [301] = { name = "Strength of the Automaton",                                        }
,   [302] = { name = "Leviathan",                                                        }
,   [303] = { name = "Lamia's Song",                                                     }
,   [304] = { name = "Medusa",                                                           }
,   [305] = { name = "Treasure Hunter",                                                  }
,   [306] = nil
,   [307] = { name = "Draugr Hulk",                                                      }
,   [308] = { name = "Bone Pirate's Tatters",                                            }
,   [309] = { name = "Knight-errant's Mail",                                             }
,   [310] = { name = "Sword Dancer",                                                     }
,   [311] = { name = "Rattlecage",                                                       }
,   [312] = { name = "Tremorscale",                                                      }
,   [313] = { name = "Masters Duel Wield",                                               }
,   [314] = { name = "Masters Two Handed",                                               }
,   [315] = { name = "Masters One Hand and Shield",                                      }
,   [316] = { name = "Masters Destruction Staff",                                        }
,   [317] = { name = "Masters Duel Wield",                                               }
,   [318] = { name = "Masters Restoration Staff",                                        }
,   [319] = nil
,   [320] = { name= "War Maiden",                                                        }
,   [321] = { name= "Defiler",                                                           }
,   [322] = { name= "Warrior-Poet",                                                      }
,   [323] = { name= "Assassin's Guile",                 trait_ct = 3, dol_set_index = 37 }
,   [324] = { name= "Daedric Trickery",                 trait_ct = 8, dol_set_index = 39 }
,   [325] = { name= "Shacklebreaker",                   trait_ct = 6, dol_set_index = 38 }
,   [326] = { name= "Vanguard's Challenge",                                              }
,   [327] = { name= "Coward's Gear",                                                     }
,   [328] = { name= "Knight Slayer",                                                     }
,   [329] = { name= "Wizard's Riposte",                                                  }
,   [330] = { name= "Automated Defense",                                                 }
,   [331] = { name= "War Machine",                                                       }
,   [332] = { name= "Master Architect",                                                  }
,   [333] = { name= "Inventor's Guard",                                                  }
,   [334] = { name= "Impregnable Armor",                                                 }
,   [335] = { name= "Draugr's Rest",                                                     }
,   [336] = { name= "Pillar of Nirn",                                                    }
,   [337] = { name= "Ironblood",                                                         }
,   [338] = { name= "Flame Blossom",                                                     }
,   [339] = { name= "Blooddrinker",                                                      }
,   [340] = { name= "Hagraven's Garden",                                                 }
,   [341] = { name= "Earthgore",                                                         }
,   [342] = { name= "Domihaus",                                                          }
,   [343] = { name = "Caluurion's Legacy",                                               }
,   [344] = { name = "Trappings of Invigoration",                                        }
,   [345] = { name = "Ulfnor's Favor",                                                   }
,   [346] = { name = "Jorvuld's Guidance",                                               }
,   [347] = { name = "Plague Slinger",                                                   }
,   [348] = { name = "Curse of Doylemish",                                               }
,   [349] = { name = "Thurvokun",                                                        }
,   [350] = { name = "Zaan",                                                             }
,   [351] = { name = "Innate Axiom",                    trait_ct = 2, dol_set_index = 41 }
,   [352] = { name = "Fortified Brass",                 trait_ct = 4, dol_set_index = 42 }
,   [353] = { name = "Mechanical Acuity",               trait_ct = 6, dol_set_index = 40 }
,   [354] = { name = "Mad Tinkerer",                                                     }
,   [355] = { name = "Unfathomable Darkness",                                            }
,   [356] = { name = "Livewire",                                                         }
,   [357] = { name = "Disciplined Slash (Perfected)",                                    }
,   [358] = { name = "Defensive Position (Perfected)",                                   }
,   [359] = { name = "Chaotic Whirlwind (Perfected)",                                    }
,   [360] = { name = "Piercing Spray (Perfected)",                                       }
,   [361] = { name = "Concentrated Force (Perfected)",                                   }
,   [362] = { name = "Timeless Blessing (Perfected)",                                    }
,   [363] = { name = "Disciplined Slash",                                                }
,   [364] = { name = "Defensive Position",                                               }
,   [365] = { name = "Chaotic Whirlwind",                                                }
,   [366] = { name = "Piercing Spray",                                                   }
,   [367] = { name = "Concentrated Force",                                               }
,   [368] = { name = "Timeless Blessing",                                                }
,   [369] = { name = "Merciless Charge",                                                 }
,   [370] = { name = "Rampaging Slash",                                                  }
,   [371] = { name = "Cruel Flurry",                                                     }
,   [372] = { name = "Thunderous Volley",                                                }
,   [373] = { name = "Crushing Wall",                                                    }
,   [374] = { name = "Precise Regeneration",                                             }
,   [375] = nil
,   [376] = nil
,   [377] = nil
,   [378] = nil
,   [379] = nil
,   [380] = { name = "Prophet's",                                                        }
,   [381] = { name = "Broken Soul",                                                      }
,   [382] = { name = "Grace of Gloom",                                                   }
,   [383] = { name = "Gryphon's Ferocity",                                               }
,   [384] = { name = "Wisdom of Vanus",                                                  }
,   [385] = { name = "Adept Rider",                     trait_ct = 3, dol_set_index = 43 }
,   [386] = { name = "Sload's Semblance",               trait_ct = 6, dol_set_index = 45 }
,   [387] = { name = "Nocturnal's Favor",               trait_ct = 9, dol_set_index = 44 }

}

local CustomMenu = LibStub("LibCustomMenu")

ZO_CreateStringId("ADD_TO_CRAFT_QUEUE", "Add to Queue")
ZO_CreateStringId("ADD_TO_CRAFT_QUEUE_ALL", "All Writs to Queue")

local function AddWritToQueue(itmLink)
	    local x = { ZO_LinkHandler_ParseLink(itmLink) }
	    local o = {
	        text             =          x[ 1]
	    ,   link_style       = tonumber(x[ 2])
	    ,   unknown3         = tonumber(x[ 3])
	    ,   item_id          = tonumber(x[ 4])
	    ,   sub_type         = tonumber(x[ 5])
	    ,   internal_level   = tonumber(x[ 6])
	    ,   enchant_id       = tonumber(x[ 7])
	    ,   enchant_sub_type = tonumber(x[ 8])
	    ,   enchant_level    = tonumber(x[ 9])
	    ,   writ1            = tonumber(x[10])
	    ,   writ2            = tonumber(x[11])
	    ,   writ3            = tonumber(x[12])
	    ,   writ4            = tonumber(x[13])
	    ,   writ5            = tonumber(x[14])
	    ,   writ6            = tonumber(x[15])
	    ,   item_style       = tonumber(x[16])
	    ,   is_crafted       = tonumber(x[17])
	    ,   is_bound         = tonumber(x[18])
	    ,   is_stolen        = tonumber(x[19])
	    ,   charge_ct        = tonumber(x[20])
	    ,   unknown21        = tonumber(x[21])
	    ,   unknown22        = tonumber(x[22])
	    ,   unknown23        = tonumber(x[23])
	    ,   writ_reward      = tonumber(x[24])
	    }



	    local item_num      = o.writ1

	    local quality_num   = o.writ3
	    local set_num       = o.writ4
	    local trait_num     = o.writ5
	    local motif_num     = o.writ6

	    local itm = Smithing.REQUEST_ITEMS[item_num]

	local requestTable = {}

	requestTable["Weight"] = {nil,""}
	if itm.school==CRAFTING_TYPE_BLACKSMITHING and itm.dol_pattern_index  < 8 then
		requestTable["Trait"] = {(trait_num + 1) , Smithing.TRAITS_WEAPON[trait_num].trait_name}
	elseif itm.school == CRAFTING_TYPE_WOODWORKING and itm.dol_pattern_index ~= 2 then
		requestTable["Trait"] = {(trait_num + 1) , Smithing.TRAITS_WEAPON[trait_num].trait_name}
	else
		requestTable["Trait"] = {(trait_num + 1) , Smithing.TRAITS_ARMOR[trait_num].trait_name}
	end

	requestTable["Pattern"] = {itm.dol_pattern_index,itm.item_name}
	requestTable["Level"] = {150,"CP150"}
	requestTable["Style"] = {motif_num, Smithing.MOTIF[motif_num].motif_name}
	requestTable["Set"]	= {Smithing.SET_BONUS[set_num].dol_set_index ,Smithing.SET_BONUS[set_num].name}
	requestTable["Quality"]	= {quality_num,Smithing.QUALITY[quality_num]}
	requestTable["Reference"] = DolgubonSetCrafter.savedvars.counter
	DolgubonSetCrafter.savedvars.counter = DolgubonSetCrafter.savedvars.counter + 1
	shortenNames(requestTable)
		local CraftRequestTable = {itm.dol_pattern_index, true,150,motif_num,(trait_num + 1), false, itm.school,  Smithing.SET_BONUS[set_num].dol_set_index , quality_num, true, requestTable["Reference"]}
		local returnedTable = LazyCrafter:CraftSmithingItemByLevel(unpack(CraftRequestTable))
		requestTable["CraftRequestTable"] = CraftRequestTable
		if returnedTable then
			addRequirements(returnedTable, true)
		end
	 queue[#queue+1] = requestTable
	 DolgubonSetCrafter.updateList()
end

local function AddWritItem(inventorySlot, slotActions)
  local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)

    if not bagId then return end

  local itemLink = GetItemLink(bagId, slotIndex)
  local icon, _, _, _,_ = GetItemLinkInfo(itemLink)

  if icon == "/esoui/art/icons/master_writ_blacksmithing.dds" or icon == "/esoui/art/icons/master_writ_clothier.dds" or icon == "/esoui/art/icons/master_writ_woodworking.dds" then
	  slotActions:AddCustomSlotAction(ADD_TO_CRAFT_QUEUE, function()

	  	AddWritToQueue(itemLink)
	    
	  end , "")

	  slotActions:AddCustomSlotAction(ADD_TO_CRAFT_QUEUE_ALL, function()

	  	local bagSize = GetBagSize(bagId)

	  	local writList = {}
	  	local writPair = {}

	  	for k=0, bagSize do
	  		local itmLink = GetItemLink(bagId, k)
  			local ico, _, _, _,_ = GetItemLinkInfo(itmLink)
  			if ico == "/esoui/art/icons/master_writ_blacksmithing.dds" or ico == "/esoui/art/icons/master_writ_clothier.dds" or ico == "/esoui/art/icons/master_writ_woodworking.dds" then
  				local x = { ZO_LinkHandler_ParseLink(itmLink) }
				local set_num       = tonumber(x[13])

				writPair[Smithing.SET_BONUS[set_num].name .. k] = itmLink
				table.insert(writList, Smithing.SET_BONUS[set_num].name .. k)

	  			--AddWritToQueue(itmLink)
	  		end
	    end

	    table.sort(writList)
	    for _, k in ipairs(writList) do AddWritToQueue(writPair[k]) end
	    
	  end , "")
  end
end
 
 CustomMenu:RegisterContextMenu(AddWritItem, CustomMenu.CATEGORY_LATE)