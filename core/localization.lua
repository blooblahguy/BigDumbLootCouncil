local bdlc, c, l = unpack(select(2, ...))

--------------------------------------
-- EN Localization Defaults (dont touch, use as reference)
--------------------------------------
-- important functionality localization
l["tierHelm"] = "Helm"
l["tierHelm"] = "Head"
l["tierShoulders"] = "Shoulders"
l["tierShoulders2"] = "Shoulder"
l["tierLegs"] = "Leggings"
l["tierLegs2"] = "Leg"
l["tierCloak"] = "Cloak"
l["tierChest"] = "Chest"
l["tierBelt"] = "Belt"
l["tierGloves"] = "Gauntlets"
l["tierGloves2"] = "Hand"
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
-- l["frameAward"] = "Award to "
l["frameAward"] = "Award Loot "
-- l["frameYes"] = "Yes"
-- l["frameNo"] = "No"
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
	l["tierProtector"] = "Protecteur"
	l["tierConqueror"] = "Conquérant"
	l["tierVanquisher"] = "Vainqueur"

	l["tierHelm"] = "Heaume"
	l["tierShoulders"] = "Epaulières"
	l["tierLegs"] = "Jambières"
	l["tierCloak"] = "Cape"
	l["tierChest"] = "Plastron"
	l["tierGloves"] = "Gantelets"
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
	l["tierProtector"] = "Beschützers"
	l["tierConqueror"] = "Eroberers"
	l["tierVanquisher"] = "Bezwingers"

	l["tierHelm"] = "Helm"
	l["tierShoulders"] = "Schultern"
	l["tierLegs"] = "Gamaschen"
	l["tierCloak"] = "Umhang"
	l["tierChest"] = "Brustschutz"
	l["tierGloves"] = "Stulpen"
	
	l["itemWarforged"] = "Kriegsgeschmiedet"
	
elseif (GetLocale() == "itIT") then
	-- Italian
	l["tierProtector"] = "Protettore"
	l["tierConqueror"] = "Conquistatore"
	l["tierVanquisher"] = "Dominatore"

	l["tierHelm"] = "Elmo"
	l["tierShoulders"] = "Spallacci"
	l["tierLegs"] = "Gambiere"
	l["tierCloak"] = "Mantello"
	l["tierChest"] = "Corazza"
	l["tierGloves"] = "Guanti Lunghi"
	
	l["itemWarforged"] = "Guerraforgiato"
	l["itemTitanforged"] = "Titanforgiato"
	
elseif (GetLocale() == "koKR") then
	-- Korean
	l["tierVanquisher"] = "제압자"
	l["tierConqueror"] = "정복자"
	l["tierProtector"] = "수호자"
	
	l["tierCloak"] = "망토"
	l["tierShoulders"] = "어깨보호구"
	l["tierLegs"] = "다리보호구"
	l["tierChest"] = "가슴보호대"
	l["tierGloves"] = "건틀릿"
	l["tierHelm"] = "투구"
	
	l["itemWarforged"] = "전쟁벼림"
	
elseif (GetLocale() == "zhCN") then
	-- Chinese
	l["tierVanquisher"] = "胜利"
	l["tierConqueror"] = "征服者"
	l["tierProtector"] = "保卫"
	
	l["tierCloak"] = "斗篷"
	l["tierShoulders"] = "护肩"
	l["tierLegs"] = "护腿"
	l["tierChest"] = "胸甲"
	l["tierGloves"] = "手"
	l["tierHelm"] = "头盔"
	
	l["itemWarforged"] = "战火"
	
elseif (GetLocale() == "ruRU") then
	-- Russian
	l["tierVanquisher"] = "покорителя"
	l["tierConqueror"] = "завоевателя"
	l["tierProtector"] = "защитника"
	
	l["tierCloak"] = "Плащ"
	l["tierShoulders"] = "Наплечники"
	l["tierLegs"] = "Поножи"
	l["tierChest"] = "Нагрудник"
	l["tierGloves"] = "Рукавицы"
	l["tierHelm"] = "Шлем"
	
	l["itemWarforged"] = "Предмет закален в бою"
	l["itemTitanforged"] = "Кованый титанами"
	
elseif (GetLocale() == "esES") then
	-- Spanish
	l["tierVanquisher"] = "vencedor"
	l["tierConqueror"] = "conquistador"
	l["tierProtector"] = "protector"
	
	l["tierCloak"] = "Capa"
	l["tierShoulders"] = "Sobrehombros"
	l["tierLegs"] = "Leotardos"
	l["tierChest"] = "Cofre"
	l["tierGloves"] = "Guanteletes"
	l["tierHelm"] = "Yelmo"
	
	l["itemWarforged"] = "Forjas de la Titanes"
	
elseif (GetLocale() == "ptBR") then
	-- Portuguese
	l["tierVanquisher"] = "Subjugador"
	l["tierConqueror"] = "Conquistador"
	l["tierProtector"] = "Protetor"
	
	l["tierCloak"] = "Manto"
	l["tierShoulders"] = "Omoplatas"
	l["tierLegs"] = "Perneiras"
	l["tierChest"] = "Torso"
	l["tierGloves"] = "Manoplas"
	l["tierHelm"] = "Elmo"
	
	l["itemWarforged"] = "Forjado para a Guerra"
	l["itemTitanforged"] = "Forjado para a Titãs"
	
end