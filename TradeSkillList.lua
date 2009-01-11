--
-- Addon to list users tradeskills in a form that can be pasted onto a phpbb3 board
--
-- This addon is based on TradeSkillList.lua by Eric Shepherd
--
-- See http://github.com/yarral/tsl
--
--

function TradeSkillList_Close()
  TradeSkillListFrame:Hide();
  TradeSkillListFrame.Box:SetText("");
end

function StartBuildingSkillList(cmd)
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

  DEFAULT_CHAT_FRAME:AddMessage(TRADESKILL_STARTING);
  
  -- First, get the name of the currently open trade skill window.
  
  tradeSkillName, currentLevel, maxLevel = GetTradeSkillLine();
  
  if tradeSkillName == TRADESKILL_UNKNOWN then
    DEFAULT_CHAT_FRAME:AddMessage(TRADESKILL_NONE_OPEN);
    return;
  end
  
  
  local player_name
  player_name= UnitName("player");

  itemList = 'Tradeskills for ' .. player_name .. "\r\n\r\n";

  -- Now we iterate over the skill list
  
  numSkills = GetNumTradeSkills();      -- Includes headers

  tsName, tsLevel, tsMaxLevel = GetTradeSkillLine()
  itemList = itemList .. tsName .. " skill " .. tsLevel .. " of " .. tsMaxLevel .. "\n\r"
  
  for curSkillIndex=1, numSkills do
    local found;
    local i;
    local numLines;
    local desc;
    local typeChar;
    local itemStats;
        
    skillName, skillType, _, _ = GetTradeSkillInfo(curSkillIndex);
    
    if (skillType == TRADESKILL_HEADER_TYPE) then
      local tweakedName = skillName.gsub(skillName, " ", "&nbsp;");
      doneFirstTopLink = 1;
      if (skillName == TRADESKILL_ENCHANT) then
        doingEnchants = 1;
      else
        doingEnchants = 0;
      end
      itemList = itemList .. '\r\n[b]' .. skillName .. '[/b]\r\n';
    else
      itemLink = GetTradeSkillItemLink(curSkillIndex);
      found, _, color, itemString = string.find(itemLink, "^|c(%x+)|H(.+)|h%[.+%]");
      found, itemId, _, _, _, _, _, _, _, _ = strsplit(":", itemString);
      
      TradeSkillListScanTooltip:ClearLines();
      TradeSkillListScanTooltip:SetTradeSkillItem(curSkillIndex);
    
      numLines = TradeSkillListScanTooltip:NumLines();

      itemList = itemList .. '[item]'.. skillName .. '[/item]\r\n';
      
    end
  end

  
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

function TradeSkillList_OnLoad()
  SLASH_TRADESKILL1 = TRADESKILL_SLASHCMD_1;
  SLASH_TRADESKILL2 = TRADESKILL_SLASHCMD_2;
  SlashCmdList["TRADESKILL"] = StartBuildingSkillList;
end