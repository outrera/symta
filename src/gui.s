use gfx reader gui_

// loop body made a separate routine, so that GC will free all per-frame data
event_loop F =
| Events = show_get_events{}.parse.0
| when got Events.locate{? >< quit}: leave [No]
| G = F Events
| less G.is_gfx: leave [G]
| Result = show_gfx G.handle
| when Result <> '': bad "show: [Result]"
| No

show F =
| while 1
  | R = event_loop F
  | when R.is_list
    | show_close
    | leave R.0


//FIXME: create a default widgets

GUI = No

widget.input In =
widget.items = No
widget.render = Me
widget.draw G PX PY =
widget.popup = 0
widget.infoline = '' //text to draw at info line
widget.pointer = 0
widget.parent = 
widget.`=parent` P = 
widget.itemAt Point XY WH =
| Items = $items
| when no Items: leave [Me XY WH]
| Item = Items.find{I => Point.in{I.meta_}}
| when no Item: leave [Me XY WH]
| [IX IY W H] = Item.meta_
| Item.itemAt{Point-[IX IY] XY+[IX IY] [W H]}
widget.x = 0
widget.y = 0
widget.w = 0
widget.h = 0
widget.above_all = 0 //draw above all other widgets
widget.wants_focus = 0
widget.wants_focus_rect = 0

type spacer.widget{W H} w/W h/H
spacer.as_text = "#spacer{[$w] [$h]}"

type tabs.~{Init Tabs} tab all/Tabs | $pick{Init}
tabs.pick TabName =
| when $tab: when got@@it get_gui: it.focus_widget <= No
| $tab <= $all.TabName
| when no $tab: bad "tabs.pick: no [TabName]"
tabs.as_text = "#tabs{[$tab]}"
tabs._ Method Args =
| Args.0 <= Args.0.tab
| Args.apply_method{Method}

type hidden.~{widget show/0} show/Show spacer/spacer{0 0}
hidden.as_text = "#hidden{show/[$show] [$widget]}"
hidden._ Method Args =
| Args.0 <= if $show then Args.0.widget else Args.0.spacer
| Args.apply_method{Method}

type canvas.widget{W H P} w/W h/H paint/P
canvas.draw G PX PY = case Me (F<~).paint: F G PX PY $w $h 

type layV.widget{Xs s/S} w/1 h/1 spacing/S items/Xs{(meta ? [0 0 1 1])}
layV.draw G X Y =
| S = $spacing
| Is = $items
| Rs = Is{?render}
| $w <= Rs{?w}.max
| $h <= Rs{?h}.infix{S}.sum
| N = 0
| for R Rs
  | W = R.w
  | H = R.h
  | Rect = Is^pop.meta_
  | RX = 0
  | RY = N
  | G.blit{X+RX Y+RY R}
  | Rect.init{[RX RY W H]}
  | N <= N+H+S

type layH.widget{Xs s/S} w/1 h/1 spacing/S items/Xs{(meta ? [0 0 1 1])}
layH.draw G X Y =
| S = $spacing
| Is = $items
| Rs = Is{?render}
| $h <= Rs{?h}.max
| $w <= Rs{?w}.infix{S}.sum
| N = 0
| for R Rs
  | W = R.w
  | H = R.h
  | Rect = Is^pop.meta_
  | RX = N
  | RY = 0
  | G.blit{X+RX Y+RY R}
  | Rect.init{[RX RY W H]}
  | N <= N+W+S

type dlg.widget{Xs w/No h/No} w/W h/H ws items rs
| $ws <= Xs{[X Y W]=>[X Y (meta W [0 0 1 1])]}
| $items <= $ws{}{?2}.flip
dlg.render =
| when got@@it $items.locate{?above_all}:
  | swap $items.0 $items.it
  | swap $ws.($ws.size-1) $ws.($ws.size-it-1)
  | $items.0.above_all <= 0
| have $w: $ws{}{?0 + ?2.render.w}.max
| have $h: $ws{}{?1 + ?2.render.h}.max
| Me
dlg.draw G PX PY =
| for [X Y W] $ws
  | R = W.render
  | Rect = W.meta_
  | X += R.x
  | Y += R.y
  | Rect.init{[X Y R.w R.h]}
  | G.blit{PX+X PY+Y R}

type input_split_item.$base_{parent base_}
input_split_item.input In = $parent.handler_{}{$base_ In}

type input_split.$base{base handler_} kids/(t)
input_split.itemAt Point XY WH =
| [Item WXY WWH] = $base.itemAt{Point XY WH}
| Addr = Item^address
| Wrap = have $kids.Addr: input_split_item Me Item
| [Wrap WXY WWH]


type gui{Root cursor/host}
  root/Root
  timers/[]
  mice_xy/[0 0]
  widget_cursor //cursor current widgets provides
  result/No
  fb/No
  keys/(t)
  popup/0
  mice_widget/(widget) //widget under cursor
  focus_widget/No //widget currently receiving keyboard input
  focus_xy/[0 0]
  focus_wh/[0 0]
  mice_focus
  mice_focus_xy/[0 0]
  click_time/(t)
  cursor/Cursor //defaut cursor
  host_cursor/0
| GUI <= Me
| $fb <= gfx 1 1
| show: Es => | GUI.input{Es}
              | GUI.render
| when got $fb
  | $fb.free
  | $fb <= No
| R = $result
| $result <= No
| GUI <= No
| leave R
gui.render =
| FB = $fb
| when no FB: leave No
| R = $root.render
| W = R.w
| H = R.h
| when W <> FB.w or H <> FB.h:
  | FB.free
  | FB <= gfx W H
  | $fb <= FB
| FB.blit{0 0 R}
| when got@@fw $focus_widget:
  | when fw.wants_focus_rect
    | P = $focus_xy+[fw.x fw.y]
    | WH = if fw.w and fw.h then [fw.w fw.h] else $focus_wh
    | FB.rectangle{#FFFF00 0 P.0-1 P.1-1 WH.0+2 WH.1+2}
| C = $widget_cursor
| when got C
  | XY = GUI.mice_xy
  | CG = if C then C else $cursor
  | when got CG and host <> CG:
    | when $host_cursor: show_cursor 0
    | $host_cursor <= 0
    | FB.blit{XY.0 XY.1 CG}
  | when host >< CG and not $host_cursor:
    | show_cursor 1
    | $host_cursor <= 1
    | Pop = 
  | when $popup
    | R = $popup.render
    | FB.blit{XY.0 XY.1-R.h R}
| FB
gui.add_timer Interval Handler =
| Me.timers <= [@Me.timers [Interval (clock)+Interval Handler]]
gui.update_timers Time =
| Ts = $timers
| less Ts.size: leave 0
| $timers <= [] // user code can insert additional timers
| Remove = []
| for [N T] Ts.i: case T [Interval Expiration Fn]:
  | when Time >> Expiration
    | if got Fn{} then Ts.N.1 <= (Time)+Interval
      else push N Remove
| when Remove.size
  | N = 0
  | Ts <= Ts.skip{X=>Remove.locate{N++}^got}
| when $timers.size: Ts <= [@Ts @$timers]
| $timers <= Ts
| 0
gui.input Es =
| T = clock
| $update_timers{T}
| [NW NW_XY NW_WH] = $root.itemAt{$mice_xy [0 0] [0 0]} //new widget
| $popup <= NW.popup
| $widget_cursor <= NW.pointer
| for E Es: case E
  [mice_move XY]
    | $mice_xy.init{XY}
    | if $mice_focus
      then $mice_focus.input{[mice_move XY XY-$mice_focus_xy]}
      else NW.input{[mice_move XY XY-NW_XY]}
    | MW = $mice_widget
    | when MW^address <> NW^address:
      | when got MW: MW.input{[mice over 0 XY]}
      | $mice_widget <= NW
      | NW.input{[mice over 1 XY]}
  [mice Button State]
    | MP = $mice_xy
    | MW = $mice_widget
    | when MW^address <> NW^address:
      | when got MW: MW.input{[mice over 0 MP]}
      | $mice_widget <= NW
      | NW.input{[mice over 1 MP]}
    | if $mice_focus
      then | LastClickTime = $click_time.Button
           | when got LastClickTime and T-LastClickTime < 0.25:
             | NW.input{[mice "double_[Button]" 1 MP-NW_XY]}
           | $click_time.Button <= T
           | $mice_focus.input{[mice Button State MP-$mice_focus_xy]}
           | less State: $mice_focus <= 0
      else | $mice_focus <= NW
           | $mice_focus_xy.init{NW_XY}
           | NW.input{[mice Button State MP-NW_XY]}
    | when State and NW.wants_focus:
      | $focus_xy <= NW_XY
      | $focus_wh <= NW_WH
      | FW = $focus_widget
      | when FW^address <> NW^address:
        | when got FW: FW.input{[focus 0 MP-$focus_xy]}
        | $focus_widget <= NW
        | NW.input{[focus 1 MP-NW_XY]}
  [key Key State] | $keys.Key <= State
                  | D = if got $focus_widget then $focus_widget else NW
                  | D.input{[key Key State]}
  Else |
| No
gui.exit @Result =
| $result <= case Result [R](R) Else(No)
| $fb <= No

// sleep for a number of seconds
gui.sleep Seconds = show_sleep: @int Seconds*1000.0

// get the number of seconds since the gui initialization.
gui.ticks = show_get_ticks{}.float/1000.0


get_gui = GUI

sound_load Filename music/0 = show_sound_load Filename Music
sound_free Id = show_sound_free Id
sound_play Id channel/-1 volume/0.5 loop/0 =
| show_sound_play Id Channel (Volume*1000.0).int Loop
sound_playing Channel = show_sound_playing Channel

export gui get_gui tabs hidden layV layH dlg spacer input_split
       sound_load sound_free sound_play sound_playing
