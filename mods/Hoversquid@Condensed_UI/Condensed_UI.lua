-- Class
Condensed_UI = Object:extend()

function Condensed_UI:init()
  local random_state = copy_table(G.GAME.pseudorandom)
  self.uibox = nil
  self.blind_sprites = self:create_ante_sprites(true)
  -- sayTable(self.blind_sprites, "BLIND SPRITES:", true)
  self:reload_UI()
  G.GAME.pseudorandom = random_state
    -- offset={x=-6.5, y=5}}
end

function Condensed_UI:reload_UI()
  if self.uibox then self.uibox:remove() end
  self.blind_sprites = self:create_ante_sprites(true)
  local def = {n=G.UIT.ROOT, config={align = "cl",colour=G.C.CLEAR}, nodes={
    {n=G.UIT.R, config={align="cl",maxw=2.075},nodes={
        self:get_sprite("Small"),
        self:get_sprite("Big"),
        self:get_sprite("Boss"),
    }}
  }}
    sayTable(def, "DEF:::::", true)
    local uibox=UIBox{
      definition=def,
      config={
        major = G.HUD:get_UIE_by_ID('blind_tracker'),
        align = 'cm',
        offset={x=0,y=0},
        colour=G.C.CLEAR,
      }
    }
    print("MADE UI BOX")
    -- sayTable(self.uibox, "UIBOX:")
    if uibox then uibox:recalculate() end
    self.uibox = uibox
    print("------ui recalc------")
    return true

end

function Condensed_UI:get_sprite(type)
  local state = G.GAME.round_resets.blind_states[type]
  if state == "Defeated" or state == "Skipped" or state == "Current" then
    return nil
  end
  print(type .. " : " .. state .. " - SPRITE MADE")
  -- sayTable(self.blind_sprites, "BLIND SPRITES")

  return self.blind_sprites[type]
end

function printTable(o, indent, max, n)
  n = n or 0
  if n < max and type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. printTable(v, indent, max, n+1) .. ','
      if indent == true then
        s = s.."\n"
      end
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function sayTable(table, label, indent)
if label ~= nil then
  tableLabel = "--------------"..label.."--------------"
  labelSize = string.len(tableLabel)
  trailingLabel = ""
  for i = 0, labelSize do
      trailingLabel = trailingLabel .. "-"
  end

  print("\n"..tableLabel.."\n\n"..printTable(table, indent, 3).."\n"..trailingLabel)
  else
      print(printTable(table, indent, 3))
  end
end

function Condensed_UI:get_ante(current)
  local small_tag, big_tag, boss
  if current then
    small_tag = G.GAME.round_resets.blind_tags["Small"]
    big_tag = G.GAME.round_resets.blind_tags["Big"]
    boss = G.P_BLINDS[G.GAME.round_resets.blind_choices["Boss"]].key
  else
    small_tag = get_next_tag_key()
    big_tag = get_next_tag_key()
    boss = get_new_boss()
  end
  G.GAME.bosses_used[boss] = G.GAME.bosses_used[boss] - 1
  return {
    Small = { blind = "bl_small", tag = small_tag },
    Big = { blind = "bl_big", tag = big_tag },
    Boss = { blind = boss }
  }
end

---@see get_ante for the information that is rendered here
function Condensed_UI:create_ante_sprites(current)
  current = current or false
  -- G.round_eval:get_UIE_by_ID("next_ante_preview").children = {}
  local returnedSprites = {}
  local prediction = self:get_ante(current)
  for _, choice in ipairs({ "Small", "Big", "Boss" }) do
      if prediction[choice] then
          local blind = G.P_BLINDS[prediction[choice].blind]
          local blind_sprite = AnimatedSprite(0, 0, 1, 1,
            G.ANIMATION_ATLAS[blind.atlas] or G.ANIMATION_ATLAS.blind_chips, blind.pos)
          blind_sprite:define_draw_steps({ { shader = 'dissolve', shadow_height = 0.05 }, { shader = 'dissolve' } })
          blind_sprite.float = true
          blind_sprite.states.hover.can = true
          blind_sprite.states.drag.can = true
          blind_sprite.states.collide.can = true
          blind_sprite.config = { blind = blind, force_focus = true }
          blind_sprite.hover = function()
            if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
              if not blind_sprite.hovering and blind_sprite.states.visible then
                blind_sprite.hovering = true
                blind_sprite.hover_tilt = 3
                blind_sprite:juice_up(0.05, 0.02)
                play_sound('chips1', math.random() * 0.1 + 0.55, 0.12)
                local vars = blind.vars
                if blind.loc_vars then
                    local locvars_return = blind:loc_vars()
                    vars = locvars_return and locvars_return.vars or vars
                end

                local tag = prediction[choice].tag
                sayTable(tag, "TAG FOR " .. choice)
                local tag_sprite
                local tag_preview_ui
                if tag then
                    local tag_object
                    self:set_orbitals(choice)
                    tag_object = Tag(tag, nil, choice)
                    -- _, tag_sprite = tag_object:generate_UI(0.625)
                    
                    -- Change this to include Blind Information
                    _, tag_sprite = tag_object:generate_UI(0.475)
                    -- if choice == "Small" then sayTable(tag_sprite, "TAG SPRITE", true) end
                    tag_preview_ui = G.P_TAGS[tag].preview_ui and G.P_TAGS[tag]:preview_ui(tag_object) or nil
      
                end

                if tag then blind_sprite.config.h_popup = self:create_blind_and_tag_popup(blind, blind.discovered, vars, tag, choice) 
                else
                  blind_sprite.config.h_popup = create_UIBox_blind_popup(blind, blind.discovered, vars)
                end
                print("HERE 3")
                blind_sprite.config.h_popup_config = {
                    align = 'cl',
                    offset = { x = -0.1, y = 0 },
                    parent = blind_sprite
                }
                Node.hover(blind_sprite)
                print("HERE 4")
              end
            end
            blind_sprite.stop_hover = function()
              blind_sprite.hovering = false; Node.stop_hover(blind_sprite)
              blind_sprite.hover_tilt = 0
            end
          print("HERE 5")
          print("made hover for choice: " .. choice)
          end

          -- local blind_preview_ui = SMODS.Mods.AntePreview.config.custom_UI and blind.preview_ui and blind:preview_ui()
          local blind_preview_ui = blind.preview_ui and blind:preview_ui()
          --     or nil
          local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante + 1) * blind.mult * G.GAME.starting_params.ante_scaling
          local tag = prediction[choice].tag
          local tag_sprite
          local tag_preview_ui
          if tag then
              local tag_object
              self:set_orbitals(choice)
              tag_object = Tag(tag, nil, choice)
              -- _, tag_sprite = tag_object:generate_UI(0.625)
              
              -- Change this to include Blind Information
              _, tag_sprite = tag_object:generate_UI(0.625)
              
              -- if choice == "Small" then sayTable(tag_sprite, "TAG SPRITE", true) end
              tag_preview_ui = G.P_TAGS[tag].preview_ui and G.P_TAGS[tag]:preview_ui(tag_object) or nil

          end
          returnedSprites[choice] =
          {
            n = G.UIT.C,
            config = {align = "cm"},
            nodes = {
              {
                n = G.UIT.R,
                nodes = {
                  { n = G.UIT.O, config = { object = blind_sprite } }
                }
              },
              blind_preview_ui and { n = G.UIT.R, config = { align = "tm" }, nodes = { blind_preview_ui }} or nil,
              {
                n = G.UIT.R,
                config = { align = "cm" },
                nodes = {
                  tag and {
                    n = G.UIT.C,
                    config = {align = "cm"}, nodes={{ 
                      n = G.UIT.O, config = { id = choice.."_tag_sprite", object = tag_sprite, colour=G.C.CLEAR
                    }}}} or nil
                  }
              },
            }
          } or nil

      end
  end
  print("MADE TAGS AND STUFF")
  return returnedSprites
end

function get_next_tag_key(append)
  if G.FORCE_TAG then return G.FORCE_TAG end
  local _pool, _pool_key = get_current_pool('Tag', nil, nil, append)
  local _tag = pseudorandom_element(_pool, pseudoseed(_pool_key))
  local it = 1
  while _tag == 'UNAVAILABLE' do
      it = it + 1
      _tag = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
  end

  return _tag
end

function Condensed_UI:set_orbitals(type)
  G.GAME.orbital_choices = G.GAME.orbital_choices or {}
  G.GAME.orbital_choices[G.GAME.round_resets.ante] = G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}
  if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then 
      local _poker_hands = {}
      for k, v in pairs(G.GAME.hands) do
          if v.visible then _poker_hands[#_poker_hands+1] = k end
      end

      G.GAME.orbital_choices[G.GAME.round_resets.ante][type] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
  end
end

local get_blind_amount_ref = get_blind_amount
function get_blind_amount(ante)
    local amount = get_blind_amount_ref(ante)
    local grave_diggers = SMODS.find_card('j_ortalab_grave_digger')
    for _, card in ipairs(grave_diggers) do
        amount = amount * card.ability.extra.multiplier
    end
    return amount
end

function Tag:generate_UI(_size)
  _size = _size or 0.8

  local tag_sprite_tab = nil

  local tag_sprite = Sprite(0,0,_size*1,_size*1,G.ASSET_ATLAS[(not self.hide_ability) and G.P_TAGS[self.key].atlas or "tags"], (self.hide_ability) and G.tag_undiscovered.pos or self.pos)
  tag_sprite.T.scale = 1
  tag_sprite_tab = {n= G.UIT.C, config={align = "cm", ref_table = self, group = self.tally}, nodes={
      {n=G.UIT.O, config={w=_size*1,h=_size*1, colour = G.C.BLUE, object = tag_sprite, focus_with_object = true}},
  }}
  tag_sprite:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'},
  })
  tag_sprite.float = true
  tag_sprite.states.hover.can = true
  tag_sprite.states.drag.can = false
  tag_sprite.states.collide.can = true
  tag_sprite.config = {tag = self, force_focus = true}

  tag_sprite.hover = function(_self)
      if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then 
          if not _self.hovering and _self.states.visible then
              _self.hovering = true
              if _self == tag_sprite then
                  _self.hover_tilt = 3
                  _self:juice_up(0.05, 0.02)
                  play_sound('paper1', math.random()*0.1 + 0.55, 0.42)
                  play_sound('tarot2', math.random()*0.1 + 0.55, 0.09)
              end

              self:get_uibox_table(tag_sprite)
              sayTable(self:get_uibox_table(tag_sprite)["ability_UIBox_table"], "UI BOX", true)
              _self.config.h_popup =  G.UIDEF.card_h_popup(_self)
              _self.config.h_popup_config = (_self.T.x > G.ROOM.T.w*0.4) and
                  {align =  'cl', offset = {x=-0.1,y=0},parent = _self} or
                  {align =  'cr', offset = {x=0.1,y=0},parent = _self}
              Node.hover(_self)
              if _self.children.alert then 
                  _self.children.alert:remove()
                  _self.children.alert = nil
                  if self.key and G.P_TAGS[self.key] then G.P_TAGS[self.key].alerted = true end
                  G:save_progress()
              end
          end
      end
  end
  tag_sprite.stop_hover = function(_self) _self.hovering = false; Node.stop_hover(_self); _self.hover_tilt = 0 end

  tag_sprite:juice_up()
  self.tag_sprite = tag_sprite

  return tag_sprite_tab, tag_sprite
end

local evaluate_round_hook = G.FUNCS.evaluate_round
function G.FUNCS.evaluate_round()
    evaluate_round_hook()
    if G.GAME.blind_on_deck == "Boss" then
        G.E_MANAGER:add_event(Event({
            func = function()
                G.HUD_blind_tracker = Condensed_UI{}
                return true
            end
        }))
    end
end

function Condensed_UI:create_blind_and_tag_popup(blind, discovered, vars, tag, choice)
  local tag_object, tag_sprite, uidef
  if tag then
    self:set_orbitals(choice)
    tag_object = Tag(tag, nil, choice)
    _, tag_sprite = tag_object:generate_UI(0.625)
    print("PRINTING UIBOX")
    tag_object:get_uibox_table(tag_sprite)
    sayTable(tag_sprite.ability_UIBox_table, "ABILITY UIBOX MAIN", true)
    uidef = UIBox{
      definition=tag_sprite.ability_UIBox_table,
      config={
        -- major = G.HUD:get_UIE_by_ID('blind_tracker'),
        major = G.ROOM_ATTACH,
        align = 'cm',
        offset={x=0,y=0}
    }}
    print("PRINTED UIBOX")
  end
  -- _, tag_sprite = tag_object:generate_UI(0.625)
  
  -- Change this to include Blind Information

  -- FROM : create_UIBox_blind_popup
  local blind_text = {}
  
  local _dollars = blind.dollars
  local target = {type = 'raw_descriptions', key = blind.key, set = 'Blind', vars = vars or blind.vars}
  if blind.collection_loc_vars and type(blind.collection_loc_vars) == 'function' then
      local res = blind:collection_loc_vars() or {}
      target.vars = res.vars or target.vars
      target.key = res.key or target.key
  end
  local loc_target = localize(target)
  local loc_name = localize{type = 'name_text', key = blind.key, set = 'Blind'}

  if discovered then 
    local ability_text = {}
    if loc_target then 
      for k, v in ipairs(loc_target) do
        ability_text[#ability_text + 1] = {n=G.UIT.R, config={align = "cm"}, nodes={{n=G.UIT.T, config={text = v, scale = 0.35, shadow = true, colour = G.C.WHITE}}}}
      end
    end
    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.4)
    blind_text[#blind_text + 1] =
      {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 2.5, padding = 0.07, colour = G.C.WHITE}, nodes={
        {n=G.UIT.R, config={align = "cm", maxw = 2.4}, nodes={
          {n=G.UIT.T, config={text = localize('ph_blind_score_at_least'), scale = 0.35, colour = G.C.UI.TEXT_DARK}},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.O, config={object = stake_sprite}},
          {n=G.UIT.T, config={text = blind.mult..localize('k_x_base'), scale = 0.4, colour = G.C.RED}},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.T, config={text = localize('ph_blind_reward'), scale = 0.35, colour = G.C.UI.TEXT_DARK}},
          {n=G.UIT.O, config={object = DynaText({string = {_dollars and string.rep(localize('$'),_dollars) or '-'}, colours = {G.C.MONEY}, rotate = true, bump = true, silent = true, scale = 0.45})}},
        }},
        ability_text[1] and {n=G.UIT.R, config={align = "cm", padding = 0.08, colour = mix_colours(blind.boss_colour, G.C.GREY, 0.4), r = 0.1, emboss = 0.05, minw = 2.5, minh = 0.9}, nodes=ability_text} or nil
      }}
  else
    blind_text[#blind_text + 1] =
      {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 2.5, padding = 0.1, colour = G.C.WHITE}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.T, config={text = localize('ph_defeat_this_blind_1'), scale = 0.4, colour = G.C.UI.TEXT_DARK}},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.T, config={text = localize('ph_defeat_this_blind_2'), scale = 0.4, colour = G.C.UI.TEXT_DARK}},
        }},
      }}
  end

  -- print("HERE 1")

  -- print("HERE 2")

  -- ADDING Tag stuff here
  -- sayTable(self:get_uibox_table(tag_sprite)["ability_UIBox_table"], "UI BOX", true)

  return {n=G.UIT.ROOT, config={align = "cm", padding = 0.05, colour = lighten(G.C.JOKER_GREY, 0.5), r = 0.1, emboss = 0.05}, nodes={
    {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 2.5, padding = 0.1, colour = not discovered and G.C.JOKER_GREY or blind.boss_colour or G.C.GREY}, nodes={
      {n=G.UIT.O, config={object = DynaText({string = discovered and loc_name or localize('k_not_discovered'), colours = {G.C.UI.TEXT_LIGHT}, shadow = true, rotate = not discovered, spacing = discovered and 2 or 0, bump = true, scale = 0.4})}},
    }},
    {n=G.UIT.R, config={align = "cm"}, nodes=blind_text},
   }}
  -- return {n=G.UIT.ROOT, config={align = "cm", padding = 0.05, colour = lighten(G.C.JOKER_GREY, 0.5), r = 0.1, emboss = 0.05}, nodes={
  --   {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 2.5, padding = 0.1, colour = not discovered and G.C.JOKER_GREY or blind.boss_colour or G.C.GREY}, nodes={
  --     {n=G.UIT.O, config={object = DynaText({string = discovered and loc_name or localize('k_not_discovered'), colours = {G.C.UI.TEXT_LIGHT}, shadow = true, rotate = not discovered, spacing = discovered and 2 or 0, bump = true, scale = 0.4})}},
  --   }},
  --   {n=G.UIT.R, config={align = "cm"}, nodes=blind_text},
    -- {n=G.UIT.R, config={align = "cm"}, nodes={
    --   {n=G.UIT.O, config={object=uidef},
    -- }},
  --  }}
 -- END: create_UIBox_blind_popup
end

function Condensed_UI:create_tag_popup(tag, _size)
  _size = _size or 0.8

  local tag_sprite_tab = nil

  local tag_sprite = Sprite(0,0,_size*1,_size*1,G.ASSET_ATLAS[(not tag.hide_ability) and G.P_TAGS[tag.key].atlas or "tags"], (tag.hide_ability) and G.tag_undiscovered.pos or tag.pos)
  tag_sprite.T.scale = 1
  tag_sprite_tab = {n= G.UIT.C, config={align = "cm", ref_table = tag, group = tag.tally}, nodes={
      {n=G.UIT.O, config={w=_size*1,h=_size*1, colour = G.C.BLUE, object = tag_sprite, focus_with_object = true}},
  }}
  tag_sprite:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'},
  })
  tag_sprite.float = true
  tag_sprite.states.hover.can = true
  tag_sprite.states.drag.can = false
  tag_sprite.states.collide.can = true
  tag_sprite.config = {tag = tag, force_focus = true}

  tag_sprite.hover = function(_self)
      if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then 
          if not _self.hovering and _self.states.visible then
              _self.hovering = true
              if _self == tag_sprite then
                  _self.hover_tilt = 3
                  _self:juice_up(0.05, 0.02)
                  play_sound('paper1', math.random()*0.1 + 0.55, 0.42)
                  play_sound('tarot2', math.random()*0.1 + 0.55, 0.09)
              end

              tag:get_uibox_table(tag_sprite)
              _self.config.h_popup =  G.UIDEF.card_h_popup(_self)
              _self.config.h_popup_config = (_self.T.x > G.ROOM.T.w*0.4) and
                  {align =  'cl', offset = {x=-0.1,y=0},parent = _self} or
                  {align =  'cr', offset = {x=0.1,y=0},parent = _self}
              Node.hover(_self)
              if _self.children.alert then 
                  _self.children.alert:remove()
                  _self.children.alert = nil
                  if tag.key and G.P_TAGS[tag.key] then G.P_TAGS[tag.key].alerted = true end
                  G:save_progress()
              end
          end
      end
  end
  tag_sprite.stop_hover = function(_self) _self.hovering = false; Node.stop_hover(_self); _self.hover_tilt = 0 end

  tag_sprite:juice_up()
  tag.tag_sprite = tag_sprite

  return tag_sprite_tab, tag_sprite
end
-- local create_UI_HUD_hook = G.create_UIBox_HUD
function create_UIBox_HUD()
  local scale = 0.4
  local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)

  local contents = {}

  local spacing = 0.025
  local temp_col = G.C.DYN_UI.BOSS_MAIN
  local temp_col2 = G.C.DYN_UI.BOSS_DARK
  contents.round = {
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={id = 'hud_hands',align = "cm", padding = 0.05, minw = 1.45, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_hud_hands'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2}, nodes={
          {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'hands_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.BLUE},shadow = true, rotate = true, scale = 2*scale}),id = 'hand_UI_count'}},
        }}
      }},
      {n=G.UIT.C, config={minw = spacing},nodes={}},
      {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.45, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_hud_discards'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'discards_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.RED},shadow = true, rotate = true, scale = 2*scale}),id = 'discard_UI_count'}},
          }}
        }},
      }},
      {n=G.UIT.C, config={align = "cm", minw=2.075}, nodes={}},
    }},
    {n=G.UIT.R, config={minh = spacing},nodes={}},
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.45*2 + spacing, minh = 1.275, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", r = 0.1, minw = 1.28*2+spacing, minh = 1.2, colour = temp_col2}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'dollars', prefix = localize('$')}}, maxw = 1.35, colours = {G.C.MONEY}, font = G.LANGUAGES['en-us'].font, shadow = true,spacing = 2, bump = true, scale = 2.2*scale}), id = 'dollar_text_UI'}}
        }},
        }},
      }},
      {n=G.UIT.C, config={align = "cm", minw=2.03}, nodes={}},
    }},
    {n=G.UIT.R, config={minh = spacing*14},nodes={}},
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={id = 'hud_ante',align = "cm", padding = 0.05, minw = 1.45, minh = 1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_ante'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2}, nodes={
          {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.round_resets, ref_value = 'ante'}}, colours = {G.C.IMPORTANT},shadow = true, font = G.LANGUAGES['en-us'].font, scale = 2*scale}),id = 'ante_UI_count'}},
          {n=G.UIT.T, config={text = " ", scale = 0.3*scale}},
          {n=G.UIT.T, config={text = "/ ", scale = 0.7*scale, colour = G.C.WHITE, shadow = true}},
          {n=G.UIT.T, config={ref_table = G.GAME, ref_value='win_ante', scale = scale, colour = G.C.WHITE, shadow = true}}
        }},
      }},
      {n=G.UIT.C, config={minw = spacing},nodes={}},
      {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.45, minh = 1, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_round'), minh = 0.33, scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2, id = 'row_round_text'}, nodes={
          {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'round'}}, colours = {G.C.IMPORTANT},shadow = true, scale = 2*scale}),id = 'round_UI_count'}},
        }},
      }},
      {n=G.UIT.C, config={minw = spacing},nodes={}},

      --blind tracker
      {n=G.UIT.C, config={align="cm",minw =2.075,colour=temp_col,emboss = 0.05,r=0.1,minh=1}, nodes={
        {n=G.UIT.R, config={align = "cm", maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = 'Blinds', minh = 0.33, scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={id='blind_tracker',align="cm",colour=temp_col2,emboss = 0.05,r=0.1,minw=2,minh=0.725}, nodes={}}
        }}
      }}
    }},
  }

contents.hand =
{n=G.UIT.R, config={align = "cm", id = 'hand_text_area', colour = darken(G.C.BLACK, 0.1), r = 0.1, emboss = 0.05, padding = 0.03}, nodes={
  {n=G.UIT.C, config={align = "cm"}, nodes={
    {n=G.UIT.R, config={align = "cm", minh = 1.1}, nodes={
      {n=G.UIT.O, config={id = 'hand_name', func = 'hand_text_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "handname_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
      {n=G.UIT.O, config={id = 'hand_chip_total', func = 'hand_chip_total_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "chip_total_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
      {n=G.UIT.T, config={ref_table = G.GAME.current_round.current_hand, ref_value='hand_level', scale = scale, colour = G.C.UI.TEXT_LIGHT, id = 'hand_level', shadow = true}}
    }},
    {n=G.UIT.R, config={align = "cm", minh = 1, padding = 0.1}, nodes={
      {n=G.UIT.C, config={align = "cr", minw = 2, minh =1, r = 0.1,colour = G.C.UI_CHIPS, id = 'hand_chip_area', emboss = 0.05}, nodes={
          {n=G.UIT.O, config={func = 'flame_handler',no_role = true, id = 'flame_chips', object = Moveable(0,0,0,0), w = 0, h = 0}},
          {n=G.UIT.O, config={id = 'hand_chips', func = 'hand_chip_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "chip_text"}}, colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3})}},
          {n=G.UIT.B, config={w=0.1,h=0.1}},
      }},
      {n=G.UIT.C, config={align = "cm"}, nodes={
        {n=G.UIT.T, config={text = "X", lang = G.LANGUAGES['en-us'], scale = scale*2, colour = G.C.UI_MULT, shadow = true}},
      }},
      {n=G.UIT.C, config={align = "cl", minw = 2, minh=1, r = 0.1,colour = G.C.UI_MULT, id = 'hand_mult_area', emboss = 0.05}, nodes={
        {n=G.UIT.O, config={func = 'flame_handler',no_role = true, id = 'flame_mult', object = Moveable(0,0,0,0), w = 0, h = 0}},
        {n=G.UIT.B, config={w=0.1,h=0.1}},
        {n=G.UIT.O, config={id = 'hand_mult', func = 'hand_mult_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "mult_text"}}, colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3})}},
      }}
    }}
  }}
}}
contents.dollars_chips = {n=G.UIT.R, config={align = "cm",r=0.1, padding = 0,colour = G.C.DYN_UI.BOSS_MAIN, emboss = 0.05, id = 'row_dollars_chips'}, nodes={
{n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
{n=G.UIT.C, config={align = "cm", minw = 1.3}, nodes={
{n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.3}, nodes={
  {n=G.UIT.T, config={text = localize('k_round'), scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
}},
{n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.3}, nodes={
  {n=G.UIT.T, config={text =localize('k_lower_score'), scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
}}
}},
{n=G.UIT.C, config={align = "cm", minw = 3.3, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK}, nodes={
{n=G.UIT.O, config={w=0.5,h=0.5 , object = stake_sprite, hover = true, can_collide = false}},
{n=G.UIT.B, config={w=0.1,h=0.1}},
{n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'chips_text', lang = G.LANGUAGES['en-us'], scale = 0.85, colour = G.C.WHITE, id = 'chip_UI_count', func = 'chip_UI_set', shadow = true}}
}}
}}
}}

contents.buttons = {
  {n=G.UIT.C, config={align = "cm", r=0.1, colour = G.C.CLEAR, shadow = true, id = 'button_area', padding = 0}, nodes={
    {n=G.UIT.C, config={align = "cm", minh = 0.65, minw = 2.25, r = 0.1, hover = true, colour = G.C.ORANGE, button = "options", shadow = true}, nodes={
      {n=G.UIT.C, config={align = "cm", maxw = 1.4, focus_args = {button = 'start', orientation = 'bm'}, func = 'set_button_pip'}, nodes={
        {n=G.UIT.T, config={text = localize('b_options'), scale = scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
    }},
    {n=G.UIT.C, config={align = "cm", minh = 0.65, minw = 0.275}},
    {n=G.UIT.C, config={id = 'run_info_button', align = "cm", minh = 0.65, minw = 2.25, r = 0.1, hover = true, colour = G.C.RED, button = "run_info", shadow = true}, nodes={
        {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.4}, nodes={
          {n=G.UIT.T, config={text = localize('b_run_info_1'), scale = 1.2*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
        }},
        {n=G.UIT.R, config={align = "cm", padding = 0, maxw = 1.4}, nodes={
          {n=G.UIT.T, config={text = localize('b_run_info_2'), scale = 1*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true, focus_args = {button = G.F_GUIDE and 'guide' or 'back', orientation = 'bm'}, func = 'set_button_pip'}}
        }}
      }},
    }}
}
  return {n=G.UIT.ROOT, config = {align = "cm", padding = -0.815,colour = G.C.UI.TRANSPARENT_DARK}, nodes={
    {n=G.UIT.R, config = {align = "cm", padding= 0.05, colour = G.C.DYN_UI.MAIN, r=0.1}, nodes={
      {n=G.UIT.R, config={align = "cm", colour = G.C.DYN_UI.BOSS_DARK, r=0.1, minh = 30, padding = 0.08}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.3}, nodes={}},
        {n=G.UIT.R, config={align = "cm", id = 'row_blind', minw = 1, minh = 3.75}, nodes={
          {n=G.UIT.B, config={w=0, h=3.64, id = 'row_blind_bottom'}, nodes={}}
        }},
        contents.dollars_chips,
        contents.hand,
        {n=G.UIT.R, config={align = "cm", id = 'row_round'}, nodes={
          {n=G.UIT.R, config={align = "cm"}, nodes=contents.round},
          
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", minw=1.55}, nodes=contents.buttons},
        }},
      }}
    }}
  }}
end

local start_run_hook = Game.start_run
function Game:start_run(args)
  start_run_hook(self,args)
--   G.E_MANAGER:add_event(Event({
--     func = function()
--         G.HUD_blind_tracker = Condensed_UI{}
--         return true
--     end
-- }))
  G.HUD_blind_tracker = Condensed_UI{}
end

local new_round_hook = new_round
function new_round()
  new_round_hook()
  if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
  -- G.E_MANAGER:add_event(Event({
  --   func = function()
  --     if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
  --   end
  -- }))
end

-- local get_new_boss_hook = get_new_boss
-- function get_new_boss()
--   local boss = get_new_boss_hook()
--   G.E_MANAGER:add_event(Event({
--     func = function()
--       if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
--     end
-- }))
--   return boss
-- end

local skip_blind_hook = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
  skip_blind_hook(e)
  print("SKIPPING BLIND")
  if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
    --     G.E_MANAGER:add_event(Event({
    -- func = function()
    --     if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
    --     return true
    -- end
  -- }))
end

function set_screen_positions()
  if G.STAGE == G.STAGES.RUN then
      -- G.hand.T.x = G.TILE_W - G.hand.T.w - 2.85
      G.hand.T.x = G.TILE_W - G.hand.T.w - 3.5

      G.hand.T.y = G.TILE_H - G.hand.T.h

      G.play.T.x = G.hand.T.x + (G.hand.T.w - G.play.T.w)/2
      G.play.T.y = G.hand.T.y - 3.6

      G.jokers.T.x = G.hand.T.x - 0.1
      G.jokers.T.y = 0

      G.consumeables.T.x = G.jokers.T.x + G.jokers.T.w + 0.2
      G.consumeables.T.y = 0

      -- G.deck.T.x = G.TILE_W - G.deck.T.w - 0.5
      -- G.deck.T.y = G.TILE_H - G.deck.T.h

      G.deck.T.x = G.TILE_W - G.deck.T.w - 16.225
      G.deck.T.y = G.TILE_H - G.deck.T.h - 1.725

      -- G.discard.T.x = G.jokers.T.x + G.jokers.T.w/2 + 0.3 + 15
      -- G.discard.T.y = 4.2

      G.discard.T.x = G.TILE_W - G.deck.T.w - 15
      G.discard.T.y = G.TILE_H - G.deck.T.h + 5

      G.hand:hard_set_VT()
      G.play:hard_set_VT()
      G.jokers:hard_set_VT()
      G.consumeables:hard_set_VT()
      G.deck:hard_set_VT()
      G.discard:hard_set_VT()
  end
  if G.STAGE == G.STAGES.MAIN_MENU then
      if G.STATE == G.STATES.DEMO_CTA then
          G.title_top.T.x = G.TILE_W/2 - G.title_top.T.w/2
          G.title_top.T.y = G.TILE_H/2 - G.title_top.T.h/2 - 2
      else
          G.title_top.T.x = G.TILE_W/2 - G.title_top.T.w/2
          G.title_top.T.y = G.TILE_H/2 - G.title_top.T.h/2 -(G.debug_splash_size_toggle and 2 or 1.2)
      end

      G.title_top:hard_set_VT()
  end
end

function add_tag(_tag, tag_size, info_offset, tag_offset)
  G.HUD_tags = G.HUD_tags or {}
  tag_offset = tag_offset or {x=-15.25,y=-11.4925}
  info_offset = info_offset or {x=-0.1,y=1.25}
  tag_size = tag_size or 0.6225
  local tag_sprite_ui = _tag:generate_UI(tag_size, info_offset)
  
  G.HUD_tags[#G.HUD_tags+1] = UIBox{
      definition = {n=G.UIT.ROOT, config={align = "cm",padding = 0.05, colour = G.C.CLEAR}, nodes={
        tag_sprite_ui
      }},
      config = {
        align = G.HUD_tags[1] and 'rm' or 'bri',
        offset = G.HUD_tags[1] and {x=0,y=0} or tag_offset,
        major = G.HUD_tags[1] and G.HUD_tags[#G.HUD_tags] or G.ROOM_ATTACH}
  }
  discover_card(G.P_TAGS[_tag.key])

  for i = 1, #G.GAME.tags do
    G.GAME.tags[i]:apply_to_run({type = 'tag_add', tag = _tag})
  end
  
  G.GAME.tags[#G.GAME.tags+1] = _tag
  _tag.HUD_tag = G.HUD_tags[#G.HUD_tags]
end

-- function Game:update_blind_select(dt)
--   if self.buttons then self.buttons:remove(); self.buttons = nil end
--   if self.shop and not G.GAME.USING_CODE then self.shop:remove(); self.shop = nil end

--   if not G.STATE_COMPLETE then
--       stop_use()
--       ease_background_colour_blind(G.STATES.BLIND_SELECT)
--       G.E_MANAGER:add_event(Event({ func = function() save_run(); return true end}))
--       G.STATE_COMPLETE = true
--       G.CONTROLLER.interrupt.focus = true
--       G.E_MANAGER:add_event(Event({ func = function() 
--       G.E_MANAGER:add_event(Event({
--           trigger = 'immediate',
--           func = function()
--               play_sound('cancel')
--               G.blind_select = UIBox{
--                   definition = create_UIBox_blind_select(),
--                   config = {align="bmi", offset = {x=-0.25,y=G.ROOM.T.y + 29},major = G.hand, bond = 'Weak'}
--               }
--               G.blind_select.alignment.offset.y = 0.8-(G.hand.T.y - G.jokers.T.y) + G.blind_select.T.h
--               G.ROOM.jiggle = G.ROOM.jiggle + 3
--               G.blind_select.alignment.offset.x = -0.25
--               G.CONTROLLER.lock_input = false
--               for i = 1, #G.GAME.tags do
--                   G.GAME.tags[i]:apply_to_run({type = 'immediate'})
--               end
--               for i = 1, #G.GAME.tags do
--                   if G.GAME.tags[i]:apply_to_run({type = 'new_blind_choice'}) then break end
--               end
--               return true
--           end
--       }))  ; return true end}))
--   end
-- end

SMODS.Blind:take_ownership("ox", {
  loc_vars = function(self)
      return { vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
  end,
  preview_ui = function(self)
      local hand_center = SMODS.PokerHands[G.GAME.current_round.most_played_poker_hand]
      local hand_sprite = Sprite(0, 0, 1, 0.13 / 0.53,
          G.ASSET_ATLAS[hand_center.atlas or "nap_poker_hands"], hand_center.pos or { x = 0, y = 0 })
      return { n = G.UIT.O, config = { object = hand_sprite } }
  end
}, true)

SMODS.Tag:take_ownership("handy", {
  preview_ui = function(self, tag)
      return { n = G.UIT.T, config = { text = localize("$") .. tostring(tag.config.dollars_per_hand * (G.GAME.hands_played or 0)), colour = G.C.MONEY, scale = 0.4 } }
  end
}, true)

SMODS.Tag:take_ownership("garbage", {
  preview_ui = function(self, tag)
      return { n = G.UIT.T, config = { text = localize("$") .. tostring(tag.config.dollars_per_discard * (G.GAME.unused_discards)), colour = G.C.MONEY, scale = 0.4 } }
  end
}, true)

SMODS.Tag:take_ownership("skip", {
  preview_ui = function(self, tag)
      return { n = G.UIT.T, config = { text = localize("$") .. tostring(tag.config.skip_bonus * ((G.GAME.skips + 1) or 1)), colour = G.C.MONEY, scale = 0.4 } }
  end
}, true)

SMODS.Tag:take_ownership("orbital", {
  preview_ui = function(self, tag)
      local hand_center = SMODS.PokerHands[tag.ability.orbital_hand]
      local hand_sprite = Sprite(0, 0, 1, 0.13 / 0.53,
          G.ASSET_ATLAS[hand_center.atlas or "nap_poker_hands"], hand_center.pos or { x = 0, y = 0 })
      return { n = G.UIT.O, config = { object = hand_sprite } }
  end
}, true)

-- SMODS.Atlas({
--   key = "poker_hands",
--   path = "hands.png",
--   px = 53,
--   py = 13,
-- })

-- for index, handname in ipairs({
--   "High Card",
--   "Pair",
--   "Two Pair",
--   "Three of a Kind",
--   "Straight",
--   "Flush",
--   "Full House",
--   "Four of a Kind",
--   "Straight Flush",
--   "Five of a Kind",
--   "Flush House",
--   "Flush Five",
-- }) do
--   SMODS.PokerHand:take_ownership(handname, {
--       atlas = "nap_poker_hands",
--       pos = { x = 0, y = index }
--   }, true)
-- end

