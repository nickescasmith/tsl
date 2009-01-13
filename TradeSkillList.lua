--
-- Addon to list users tradeskills in a form that can be pasted onto a phpbb3 board
--
-- This addon is based on TradeSkillList.lua by Eric Shepherd
--
-- See http://github.com/yarral/tsl
--
--

--
-- Some strings for example "Food & Drink" need to be quoted in XML
-- This is not a fully working function - TODO: Improve, but it's good enough for now
--
function tslQuoteXML(str)
   return string.replace(str, "&", "&amp;")
end


--
-- Generate XML formatted data from the tradeskill data list
--

function tslGenerateXML(tsData)
  local itemList = '<?xml version="1.0"?>\n'
  itemList = itemList .. '<skills user="' .. tsData.name .. '" type="' .. tsData.type .. '">\n'

  for index, group in pairs(tsData.items) do
     itemList = itemList .. '  <group name="' .. tslQuoteXML(group.title) .. '">\n'
     for index2, item in pairs(group.items) do
        itemList = itemList .. '      <item name="' .. tslQuoteXML(item.name) .. '" level="' .. item.level .. '">\n';
     end
     itemList  = itemList .. "  </group>\n"
  end

  itemList = itemList .. '</skills>\n'
  return itemList
end

--
-- Generate PHPBB3 formatted data from the tradeskill data list
-- (Assumes the [item] bbcode exists, will implement a more generic one which colors items etc.)
--
function tslGeneratePHPBB3(tsData)
  itemList = tsData.type .. ' for ' .. tsData.name .. '\n\n'

  for index, group in pairs(tsData.items) do
     itemList = itemList .. '[b]' .. group.title .. '[/b]\n'
     for index2, item in pairs(group.items) do
        itemList = itemList .. '[item]' ..item.name .. '[/item] (' .. item.level .. ')\n';
     end
  end
  return itemList
end

--
-- Generate HTML formatted data from the tradeskill data list
-- (Currently not working due to changed data structures for groups)
--
function tslGenerateHTML(tsData)
  itemList =  tsData.type .. " for " .. tsData.name .. "<br><br?\n"

  for index, item in pairs(tsData.items) do
     itemList = itemList .. "<font color='#" ..item.color .. "'>".. item.name .. '</font>(' .. item.level .. ')<br>\n';
  end

  return itemList
end


--
-- return data for tradeskill
--

function tslBuildSkillList()
 local topText = "";
  local text = "";
  local tradeSkillName, currentLevel, maxLevel;
  local numSkills;
  local curSkillIndex;
  local skillName, skillType;
  local itemLink, itemString;
  local subSpellName;
  local itemId;
  local i;
  local doneFirstTopLink = 0;
  local doingEnchants = 0;
  local player_name

  local tsData = {};


  -- First, get the name of the currently open trade skill window.
  tradeSkillName, currentLevel, maxLevel = GetTradeSkillLine();
  
  if tradeSkillName == TRADESKILL_UNKNOWN then
    DEFAULT_CHAT_FRAME:AddMessage(TRADESKILL_NONE_OPEN);
    return tsData;
  end
  
  -- Add a header to the tradeskill list with the character name, tradeskill type, and level
  player_name= UnitName("player");
  tsData.name = player_name;
  tsData.type = tradeSkillName;
  tsData.items = {}


  -- Now we iterate over the skill list
  
  numSkills = GetNumTradeSkills();      -- Includes headers

  local group;
  for curSkillIndex=1, numSkills do
    local found;
    local i;
    local numLines;
    local desc;
    local typeChar;
    local itemStats;
        
    skillName, skillType, _, _ = GetTradeSkillInfo(curSkillIndex);
    
    if (skillType == TRADESKILL_HEADER_TYPE) then
      table.insert(tsData.items, group)
      group = {}
      group.title = skillName
      group.items = {}
    else
      itemLink = GetTradeSkillItemLink(curSkillIndex);
      found, _, color, itemString = string.find(itemLink, "^|c(%x+)|H(.+)|h%[.+%]");
      found, itemId, _, _, _, _, _, _, _, _ = strsplit(":", itemString);
      
      TradeSkillListScanTooltip:ClearLines();
      TradeSkillListScanTooltip:SetTradeSkillItem(curSkillIndex);
    
      local itemName;
      local itemLink;
      local itemRarity;
      local itemLevel;
 
      itemName, itemLink, itemRarity, itemLevel = GetItemInfo(itemId);
      if itemLevel == null then
          itemLevel = "?"
      end

      local data = {}
      data.level = itemLevel
      data.name = skillName
      data.color = color;

      table.insert(group.items, data)
      
    end

  end
  -- Might be one group not added so add it now
  table.insert(tsData.items, group)
  return tsData
end





function tslDisplayResults(itemList)
  
  DEFAULT_CHAT_FRAME:AddMessage(TRADESKILL_DONE);
  
  -- Show the trade skill list window
  
  local skillFrame = nil;
  
  skillFrame = TradeSkillListFrame;
  if skillFrame == nil then
    skillFrame = CreateFrame("Frame", "TradeSkillListFrame", UIParent);
  end
  
  skillFrame:Hide();
  skillFrame:SetPoint("CENTER", "UIParent", "CENTER");
  skillFrame:SetFrameStrata("DIALOG");
  skillFrame:SetHeight(600);
  skillFrame:SetWidth(800);
  skillFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 9, right = 9, top = 9, bottom = 9 }
	});
	skillFrame:SetBackdropColor(0, 0, 0, 0.8);
	
  -- Add the Close button
  
  skillFrame.DoneButton = CreateFrame("Button", "TradeSkillListViewCloseButton", skillFrame, "OptionsButtonTemplate");
  skillFrame.DoneButton:SetText(TRADESKILL_CLOSE);
  skillFrame.DoneButton:SetPoint("BOTTOMRIGHT", skillFrame, "BOTTOMRIGHT", -10, 10);
  skillFrame.DoneButton:SetScript("OnClick", TradeSkillList_Close);
  
  -- Create the scroll frame
  
  skillFrame.Scroll = CreateFrame("ScrollFrame", "TradeSkillListViewScrollFrame", skillFrame, "UIPanelScrollFrameTemplate");
  skillFrame.Scroll:SetPoint("TOPLEFT", skillFrame, "TOPLEFT", 20, -20);
  skillFrame.Scroll:SetPoint("RIGHT", skillFrame, "RIGHT", -30, 0);
  skillFrame.Scroll:SetPoint("BOTTOM", skillFrame.DoneButton, "TOP", 0, 20);
  
  -- Create the edit box and insert it into the scroll frame
  
  skillFrame.Box = CreateFrame("EditBox", "TradeSkillListEditBox", skillFrame.Scroll);
  skillFrame.Box:SetWidth(750);
  skillFrame.Box:SetHeight(85);
  skillFrame.Box:SetFontObject("ChatFontNormal");
  skillFrame.Box:SetMultiLine(true);
  skillFrame.Scroll:SetScrollChild(skillFrame.Box);
--  skillFrame.Box:SetText(topText .. text);
  skillFrame.Box:SetText(itemList);

  skillFrame.Box:HighlightText();  
  
  skillFrame.Box:SetScript("OnTextChanged", function(this)
    skillFrame.Scroll:UpdateScrollChildRect();
  end);
  
  skillFrame:Show();
  skillFrame.Box:HighlightText();  
end



function StartBuildingXMLSkillList(cmd)
  
  local tsData = tslBuildSkillList()
  local itemList = tslGenerateXML(tsData)
  tslDisplayResults(itemList)
end


function StartBuildingPHPBBSkillList(cmd)
  local tsData = tslBuildSkillList()
  local itemList = tslGeneratePHPBB3(tsData)
  tslDisplayResults(itemList)
end

function StartBuildingHTMLSkillList(cmd)
  local tsData = tslBuildSkillList()
  local itemList = tslGenerateHTML(tsData)
  tslDisplayResults(itemList)
end


function TradeSkillList_Close()
  TradeSkillListFrame:Hide();
  TradeSkillListFrame.Box:SetText("");
end

function TradeSkillList_OnLoad()

  SLASH_TRADESKILLXML1 = TRADESKILL_SLASHCMD_1;
  SLASH_TRADESKILLXML2 = TRADESKILL_SLASHCMD_3;
  SlashCmdList["TRADESKILLXML"] = StartBuildingXMLSkillList;

  SLASH_TRADESKILLPHP1 = TRADESKILL_SLASHCMD_4;
  SlashCmdList["TRADESKILLPHP"] = StartBuildingPHPBBSkillList;

  SLASH_TRADESKILLHTML1 = TRADESKILL_SLASHCMD_5;
  SlashCmdList["TRADESKILLHTML"] = StartBuildingHTMLSkillList;
end