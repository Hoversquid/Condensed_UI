Condensed_UI = Object:extend()
function Condensed_UI:init(args)
  local predict = args.predict
  if predict then
    local random_state = copy_table(G.GAME.pseudorandom)
    self.blind_sprites = self:create_ante_sprites(true)
    G.GAME.pseudorandom = random_state
    self:reload_UI(true)
  else
    self.blind_sprites = self:create_ante_sprites(false)
    self:reload_UI(false)
  end
end

function Condensed_UI:reload_UI(make_new)
  make_new = make_new or false
  local def = {n=G.UIT.ROOT, config={align = "cm",colour=G.C.CLEAR}, nodes={
    {n=G.UIT.C, config={align="cm",minw=2.075, color=G.C.DYN_UI.BOSS_DARK},nodes={

    {n=G.UIT.R, config={align="cm",maxw=2.075},nodes={
        self:get_sprite("Small", make_new) or nil,
        self:get_sprite("Big", make_new) or nil,
        self:get_sprite("Boss", make_new) or nil,
      }}
    }}}}
  self.uibox=UIBox{
    definition=def,
    config={
      major = G.HUD:get_UIE_by_ID('blind_tracker'),
      align = 'cm',
      offset={x=0,y=0},
      colour=G.C.CLEAR,
      bond="Weak"
    }
  }
  self.uibox:recalculate()
end

function Condensed_UI:remove_cleared_blind(type)
  local state = G.GAME.round_resets.blind_states[type]
  -- print("type: " .. type)
  -- print(" - state: " .. state)
  if state == "Defeated" or state == "Skipped" or state == "Current" then
    local check = self.uibox and self.uibox:get_UIE_by_ID(type.."_sprite_UIBox")
    if check then
      check:remove()
      -- print("REMOVING: " .. type.."_sprite_UIBox")
    end
    return true
  end
  return false
end

function Condensed_UI:get_sprite(type, making_new)
  making_new = making_new or false

  local UI_Color
  if type == "Boss" then UI_Color = G.C.DYN_UI.BOSS_DARK
  else UI_Color = G.C.DYN_UI.BOSS_MAIN end
  -- print("TYPE: " .. type)
  -- sayTable(UI_Color, "UI_COLOR")
  local spriteUIBox
  if not making_new and self:remove_cleared_blind(type) then
    spriteUIBox = nil
  else
    spriteUIBox = UIBox{
      definition = self.blind_sprites[type],
      config = {align='cm', colour=G.C.CLEAR }
    }
  end

  return {
    n = G.UIT.C,
    config = {align = "cm",colour=G.C.CLEAR},
    nodes = {
      spriteUIBox and {n = G.UIT.O, config={object=spriteUIBox, id=type.."_sprite_UIBox", colour=G.C.CLEAR}}
    }
  }
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

  -- print("\n"..tableLabel.."\n\n"..printTable(table, indent, 3).."\n"..trailingLabel)
  else
      -- print(printTable(table, indent, 3))
  end
end

function Condensed_UI:get_ante(predict)
  local small_tag, big_tag, boss
  if predict then
    small_tag = get_next_tag_key()
    big_tag = get_next_tag_key()
    boss = get_new_boss()
    G.GAME.bosses_used[boss] = G.GAME.bosses_used[boss] - 1
  else
    small_tag = G.GAME.round_resets.blind_tags["Small"]
    big_tag = G.GAME.round_resets.blind_tags["Big"]
    boss = G.P_BLINDS[G.GAME.round_resets.blind_choices["Boss"]].key
  end
  return {
    Small = { blind = "bl_small", tag = small_tag },
    Big = { blind = "bl_big", tag = big_tag },
    Boss = { blind = boss }
  }
end

---@see get_ante for the information that is rendered here
function Condensed_UI:create_ante_sprites(predict, types)
  predict = predict or false
  types = types or { "Small", "Big", "Boss" }
  local returnedSprites = {}
  local prediction = self:get_ante(predict)
  for _, choice in ipairs(types) do
      if prediction[choice] then
          local blind = G.P_BLINDS[prediction[choice].blind]
          local scale = choice == "Boss" and 0.725 or 0.375
          local blind_sprite = AnimatedSprite(0, 0, scale, scale,
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
                blind_sprite.config.h_popup = self:create_UIBox_blind_popup(blind, choice, vars)
                blind_sprite.config.h_popup_config = {
                    align = 'cr',
                    offset = { x = 0.1, y = -0.5 },
                    parent = blind_sprite
                }
                Node.hover(blind_sprite)
              end
            end
            blind_sprite.stop_hover = function()
              blind_sprite.hovering = false; Node.stop_hover(blind_sprite)
              blind_sprite.hover_tilt = 0
            end
          end
          local tag = prediction[choice].tag
          local tag_sprite
          if tag then
              local tag_object
              self:set_orbitals(choice)
              tag_object = Tag(tag, nil, choice)
              _, tag_sprite = tag_object:generate_UI(0.375)

          end

          returnedSprites[choice] =
          {
            n=G.UIT.ROOT, config={align = "cl", colour=G.C.CLEAR}, nodes={
            {
              n = G.UIT.C,
              config = {align = "cm", minw=0.65},
              nodes = {
                {
                  n = G.UIT.R,
                  nodes = {
                    { n = G.UIT.O, config = { object = blind_sprite } }
                  }
                },
                -- blind_preview_ui and { n = G.UIT.R, config = { id = choice.."_blind_sprite", align = "tm" }, nodes = { blind_preview_ui }} or nil,
                {
                  n = G.UIT.R,
                  config = { align = "cm" },
                  nodes = {
                    tag and {
                      n = G.UIT.C,
                      config = {align = "cm"}, nodes={{
                        n = G.UIT.O, config = { id = choice.."_tag_sprite", object = tag_sprite, colour=G.C.CLEAR}
                      }}} or nil
                    }
                },
              }
            }}
          }

      end
  end
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

local get_blind_amount_ref = get_blind_amount
function get_blind_amount(ante)
    local amount = get_blind_amount_ref(ante)
    local grave_diggers = SMODS.find_card('j_ortalab_grave_digger')
    for _, card in ipairs(grave_diggers) do
        amount = amount * card.ability.extra.multiplier
    end
    return amount
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

function Tag:generate_UI(_size, tag_offset)
  tag_offset = tag_offset or {x=-0.1,y=0}
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
                  -- for Cryptid mod 
                  if self.key == 'tag_cry_cat' and not self.hide_ability then
                    play_sound('cry_meow'..math.random(4), 1.26, 0.12);
                  end
                  play_sound('tarot2', math.random()*0.1 + 0.55, 0.09)
              end

              self:get_uibox_table(tag_sprite)
              -- sayTable(self:get_uibox_table(tag_sprite)["ability_UIBox_table"], "UI BOX", true)
              _self.config.h_popup =  G.UIDEF.card_h_popup(_self)
              _self.config.h_popup_config = (_self.T.x > G.ROOM.T.w*0.4) and
              {align = 'cl', offset =tag_offset,parent = _self} or
              {align = 'cr', offset =tag_offset,parent = _self}
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

function Tag:remove()
  self:remove_from_game()
  local HUD_tag_key = nil
  for k, v in pairs(G.HUD_tags) do
      if v == self.HUD_tag then HUD_tag_key = k end
  end

  if HUD_tag_key then 
      if G.HUD_tags and G.HUD_tags[HUD_tag_key+1] then
          if HUD_tag_key == 1 then
              G.HUD_tags[HUD_tag_key+1]:set_alignment({type = 'bri',
              offset = {x=-15.25,y=-11.4925},
              xy_bond = 'Weak',
              major = G.ROOM_ATTACH})
          else
              G.HUD_tags[HUD_tag_key+1]:set_role({
              xy_bond = 'Weak',
              major = G.HUD_tags[HUD_tag_key-1]})
          end
      end
      table.remove(G.HUD_tags, HUD_tag_key)
  end

  self.HUD_tag:remove()
end

function create_UIBox_HUD()
  local scale = 0.4
  local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)

  local contents = {}

  local spacing = 0.025
  local temp_col = G.C.DYN_UI.BOSS_MAIN
  local temp_col2 = G.C.DYN_UI.BOSS_DARK
  contents.round = {
    {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
      {n=G.UIT.C, config={id = 'hud_hands',align = "cm", padding = 0.05, minw = 1.415, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_hud_hands'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.2, colour = temp_col2}, nodes={
          {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'hands_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.BLUE},shadow = true, rotate = true, scale = 2*scale}),id = 'hand_UI_count'}},
        }}
      }},
      {n=G.UIT.C, config={minw = spacing},nodes={}},
      {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.415, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.33, maxw = 1.35}, nodes={
          {n=G.UIT.T, config={text = localize('k_hud_discards'), scale = 0.85*scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.R, config={align = "cm", r = 0.1, minw = 1.45, colour = temp_col2}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'discards_left'}}, font = G.LANGUAGES['en-us'].font, colours = {G.C.RED},shadow = true, rotate = true, scale = 2*scale}),id = 'discard_UI_count'}},
          }}
        }},
      }},
      {n=G.UIT.C, config={align = "cm", minw=2.12}, nodes={}},
    }},
    {n=G.UIT.R, config={minh = spacing*10},nodes={}},
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 1.415*2 + 0.15, minh = 1.225, colour = temp_col, emboss = 0.05, r = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", r = 0.1, minw = 1.28*2+spacing, minh = 1, colour = temp_col2}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'dollars', prefix = localize('$')}}, maxw = 1.35, colours = {G.C.MONEY}, font = G.LANGUAGES['en-us'].font, shadow = true,spacing = 2, bump = true, scale = 2.2*scale}), id = 'dollar_text_UI'}}
        }},
        }},
      }},
      {n=G.UIT.C, config={align = "cm", minw=2.12}, nodes={}},
    }},
    {n=G.UIT.R, config={minh = spacing*12},nodes={}},
    --  padding = 0.025
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
      {n=G.UIT.C, config={align="cm",minw =2.075,colour=temp_col,emboss = 0.05,r=0.1,minh=1, padding = 0.05}, nodes={
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
    {n=G.UIT.R, config={align = "cm", minh = 0.765}, nodes={
      {n=G.UIT.O, config={id = 'hand_name', func = 'hand_text_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "handname_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
      {n=G.UIT.O, config={id = 'hand_chip_total', func = 'hand_chip_total_UI_set',object = DynaText({string = {{ref_table = G.GAME.current_round.current_hand, ref_value = "chip_total_text"}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, float = true, scale = scale*1.4})}},
      {n=G.UIT.T, config={ref_table = G.GAME.current_round.current_hand, ref_value='hand_level', scale = scale, colour = G.C.UI.TEXT_LIGHT, id = 'hand_level', shadow = true}}
    }},
    {n=G.UIT.R, config={align = "cm", minh = 0.765, padding = 0.1}, nodes={
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
{n=G.UIT.C, config={align = "cm", minw = 3.3, minh = 0.615, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK}, nodes={
{n=G.UIT.O, config={w=0.5,h=0.5 , object = stake_sprite, hover = true, can_collide = false}},
{n=G.UIT.B, config={w=0.1,h=0.1}},
{n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'chips_text', lang = G.LANGUAGES['en-us'], scale = 0.85, colour = G.C.WHITE, id = 'chip_UI_count', func = 'chip_UI_set', shadow = true}}
}}
}}
}}

contents.buttons = {
  {n=G.UIT.C, config={align = "cm", r=0.1, colour = G.C.CLEAR, shadow = true, id = 'button_area', padding = -0.0295}, nodes={
    {n=G.UIT.C, config={align = "cm", minh = 0.65, minw = 2.25, r = 0.1, hover = true, colour = G.C.ORANGE, button = "options", shadow = true}, nodes={
      {n=G.UIT.C, config={align = "cm", maxw = 1.4, focus_args = {button = 'start', orientation = 'bm'}, func = 'set_button_pip'}, nodes={
        {n=G.UIT.T, config={text = localize('b_options'), scale = scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
    }},
    {n=G.UIT.C, config={align = "cm", minh = 0.25, minw = 0.275}},
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
  return {n=G.UIT.ROOT, config = {align = "cm", padding = -0.69, colour = G.C.UI.TRANSPARENT_DARK}, nodes={
    {n=G.UIT.R, config = {align = "cm", padding= 0.05, colour = G.C.DYN_UI.MAIN, r=0.1}, nodes={
      {n=G.UIT.R, config={align = "cm", colour = G.C.DYN_UI.BOSS_DARK, r=0.1, minh = 30, padding = 0.08}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.3}, nodes={}},
        {n=G.UIT.R, config={align = "cm", id = 'row_blind', minw = 1, minh = 3.75}, nodes={
          {n=G.UIT.B, config={w=0, h=3.64, id = 'row_blind_bottom'}, nodes={}}
        }},
        contents.dollars_chips,
        contents.hand,
        {n=G.UIT.R, config={align = "cm", id = 'row_round'}, nodes={
        -- {n=G.UIT.R, config={minh = spacing*2},nodes={}},

          {n=G.UIT.R, config={align = "cm"}, nodes=contents.round},
          
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", minw=1.55}, nodes=contents.buttons},
        }},
      }}
    }}
  }}
end

function Condensed_UI:reroll_boss()
  -- print("REROLLING BOSS")
  local check = self.uibox:get_UIE_by_ID("Boss_sprite_UIBox")
  if check then
    -- print("FOUND BOSS: " .. check.config.id)
    check:remove()
    self.blind_sprites["Boss"] = self:create_ante_sprites(false, {"Boss"})["Boss"]
    self:reload_UI()
  end
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

      G.deck.T.x = G.TILE_W - G.deck.T.w - 16
      G.deck.T.y = G.TILE_H - G.deck.T.h - 1.81

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

local start_run_hook = Game.start_run
function Game:start_run(args)
  -- print("START RUN")
  start_run_hook(self,args)
  G.HUD_blind_tracker = Condensed_UI{predict = false}
  -- G.E_MANAGER:add_event(Event({
  --   trigger = 'after',
  --   delay = 0.25,
  --   func = function()
  --     G.HUD_blind_tracker = Condensed_UI{predict = false}
  --     return true
  --   end}))

end

local new_round_hook = new_round
function new_round()
  new_round_hook()
  if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
  -- G.E_MANAGER:add_event(Event({
  --   trigger = 'after',
  --   delay = 0.25,
  --   func = function()
  -- if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI()
  --     return true
  --   end}))
end

local reroll_boss_hook = G.FUNCS.reroll_boss
function G.FUNCS.reroll_boss(e)
  reroll_boss_hook(e)
  if G.HUD_blind_tracker then G.HUD_blind_tracker:reroll_boss() end

  -- G.E_MANAGER:add_event(Event({
  --   trigger = 'after',
  --   delay = 0.25,
  --   func = function()
  --     if G.HUD_blind_tracker then G.HUD_blind_tracker:reroll_boss() end
  --     return true
  --   end}))
end

local skip_blind_hook = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
  skip_blind_hook(e)
  if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end

  -- G.E_MANAGER:add_event(Event({
  --   trigger = 'after',
  --   delay = 0.25,
  --   func = function()
  --   if G.HUD_blind_tracker then G.HUD_blind_tracker:reload_UI() end
  --   return true
  --   end}))
end

local cash_out_hook = G.FUNCS.cash_out
function G.FUNCS.cash_out(e)
  cash_out_hook(e)
  if G.GAME.round_resets.blind_states["Small"] ~= "Defeated" then
    print("RELOADING UI ON SMALL BLIND")
    G.HUD_blind_tracker.uibox:remove()
    G.HUD_blind_tracker = Condensed_UI{predict = false}
    -- G.E_MANAGER:add_event(Event({
    --   trigger = 'after',
    --   delay = 0.25,
    --     func = function()
    --       print("RELOADING UI ON SMALL BLIND")
    --       G.HUD_blind_tracker.uibox:remove()
    --       G.HUD_blind_tracker = Condensed_UI{predict = false}
    --       return true
    --     end
    -- }))
  end
end

function Condensed_UI:create_UIBox_blind_popup(blind, choice, vars)
  local blind_text = {}
  local _dollars = blind.dollars
  local _reward = true
  if G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward[choice] then _reward = nil end

  -- sayTable(_dollars, "DOLLARS")
  local target = {type = 'raw_descriptions', key = blind.key, set = 'Blind', vars = vars or blind.vars}
  if blind.collection_loc_vars and type(blind.collection_loc_vars) == 'function' then
      local res = blind:collection_loc_vars() or {}
      target.vars = res.vars or target.vars
      target.key = res.key or target.key
  end
  local loc_target = localize(target)
  local loc_name = localize{type = 'name_text', key = blind.key, set = 'Blind'}
  local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante) * blind.mult * G.GAME.starting_params.ante_scaling
  local blind_amt_text = { n = G.UIT.T, config = { text = number_format(blind_amt), colour = G.C.RED, scale = score_number_scale(0.8, blind_amt) } }
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
        blind_amt_text
        -- {n=G.UIT.T, config={text = blind.mult..localize('k_x_base'), scale = 0.4, colour = G.C.RED}},
      }},
      _reward and {n=G.UIT.R, config={align = "cm"}, nodes={
        {n=G.UIT.T, config={text = localize('ph_blind_reward'), scale = 0.35, colour = G.C.UI.TEXT_DARK}},
        {n=G.UIT.O, config={object = DynaText({string = {_dollars and string.rep(localize('$'),_dollars) or '-'}, colours = {G.C.MONEY}, rotate = true, bump = true, silent = true, scale = 0.45})}},
      }} or nil,
      ability_text[1] and {n=G.UIT.R, config={align = "cm", padding = 0.08, colour = mix_colours(blind.boss_colour, G.C.GREY, 0.4), r = 0.1, emboss = 0.05, minw = 2.5, minh = 0.9}, nodes=ability_text} or nil
    }}
 return {n=G.UIT.ROOT, config={align = "cm", padding = 0.05, colour = lighten(G.C.JOKER_GREY, 0.5), r = 0.1, emboss = 0.05}, nodes={
  {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 2.5, padding = 0.1, colour = blind.boss_colour or G.C.GREY}, nodes={
    {n=G.UIT.O, config={object = DynaText({string = loc_name, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, rotate = true, spacing =2, bump = true, scale = 0.4})}},
  }},
  {n=G.UIT.R, config={align = "cm"}, nodes=blind_text},
 }}
end