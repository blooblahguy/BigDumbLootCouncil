local bdlc, c, l = unpack(select(2, ...))

--------------------------------------
-- EN Localization Defaults (dont touch, use as reference)
--------------------------------------
-- important functionality localization
l["itemWarforged"] = "Warforged"
l["itemTitanforged"] = "Titanforged"

-- frame/button localizations
l["frameMain"] = "Mainspec"
l["frameMinorUp"] = "Minor Up"
l["frameOffspec"] = "Offspec"
l["frameReroll"] = "Reroll"
l["frameTransmog"] = "Transmog"
l["frameNote"] = "Note"
l["framePass"] = "Pass"
l["frameVote"] = "Vote"
l["frameVoted"] = "Unvote"
l["frameVotes"] = "Votes"
l["frameNotes"] = "Notes"
l["frameOkay"] = "Okay"
l["frameInterest"] = "Interest"
l["frameCurrentGear"] = "Current Gear"
l["frameConsidering"] = "considering..."
l["frameRank"] = "Rank"
l["frameName"] = "Name"
l["frameAward"] = "Award to "
l["frameYes"] = "Yes"
l["frameNo"] = "No"
l["frameEndSession"] = "End Session"
l["frameIlvl"] = "ilvl"
l["frameItem"] = "Item Name"
l["frameLC"] = "Loot Council"


--l["relicType"] = "(%w+) Artifact Relic" -- the (%w+) represents where the relic name would be - for tooltip scanning
--------------------------------------
-- Other Client Localizations - submit changes to 
-- http://www.wowinterface.com/downloads/info23388-BigDumbLootCouncil.html#comments
-- or
-- https://wow.curseforge.com/projects/big-dumb-loot-council
--------------------------------------
if (GetLocale() == "frFR") then
	-- French 
	l["itemWarforged"] = "De guerre"
	l["itemTitanforged"] = "Forgé par les titans"

	-- frame/button FR
	l["frameMain"] = "Spé principale"
	l["frameMinorUp"] = "Up mineur"
	l["frameOffspec"] = "2nd spé"
	l["frameReroll"] = "Reroll"
	l["frameTransmog"] = "Transmo"
	l["frameNote"] = "Note"
	l["framePass"] = "Passer"
	l["frameVote"] = "Voter"
	l["frameVotes"] = "Votes"
	l["frameNotes"] = "Notes"
	l["frameOkay"] = "Okay"
	l["frameInterest"] = "Intéressé(e)"
	l["frameCurrentGear"] = "Stuff actuel"
	l["frameConsidering"] = "Réfléchis..."
	l["frameRank"] = "Rang"
	l["frameName"] = "Nom"
	l["frameAward"] = "Gagnant "
	l["frameYes"] = "Oui"
	l["frameNo"] = "Non"
	l["frameEndSession"] = "Cloturer"
	l["frameIlvl"] = "ilvl"
	l["frameItem"] = "Nom d'objet"
	l["frameLC"] = "Loot Council"

elseif (GetLocale() == "deDE") then
	-- German	
	l["itemWarforged"] = "Kriegsgeschmiedet"
	
elseif (GetLocale() == "itIT") then
	-- Italian	
	l["itemWarforged"] = "Guerraforgiato"
	l["itemTitanforged"] = "Titanforgiato"
	
elseif (GetLocale() == "koKR") then
	-- Korean	
	l["itemWarforged"] = "전쟁벼림"
	
elseif (GetLocale() == "zhCN") then
	-- Chinese	
	l["itemWarforged"] = "战火"
	
elseif (GetLocale() == "ruRU") then
	-- Russian	
	l["itemWarforged"] = "Предмет закален в бою"
	l["itemTitanforged"] = "Кованый титанами"
	
elseif (GetLocale() == "esES") then
	-- Spanish	
	l["itemWarforged"] = "Forjas de la Titanes"
	
elseif (GetLocale() == "ptBR") then
	-- Portuguese	
	l["itemWarforged"] = "Forjado para a Guerra"
	l["itemTitanforged"] = "Forjado para a Titãs"
end