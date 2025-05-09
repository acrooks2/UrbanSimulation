extensions [gis]

globals[
  upper  ;;the upper edge of exit
  lower  ;;the lower edge of exit
  move-speed ;;how many patches did people move in last tick on average. max = 1 patch/tick
  alist  ;;used in calculating the shortest distance to exits
  the-row         ;;used in export-data. it is the row being written

  elevation-dataset
  path-dataset
]

turtles-own[
  moved? ;;if it moved in this tick
]

patches-own[
  exit  ;;1 if it is an exit, 0 if it is not
  elelist ;;a list of elevations to the exits
  elevation  ;;elevation at this point is equal to shortest distance to exits
  path  ;;how many times it has been chosen as a path
]

to setup
 ca
 reset-ticks
 file-close

  ;draw-gridlines

  ifelse Number_of_exits = 2 [
  set elevation-dataset gis:load-dataset "data/mincosf1.asc"][

  set elevation-dataset gis:load-dataset "data/costdist_lower.asc"]

  gis:set-world-envelope gis:envelope-of elevation-dataset

  gis:apply-raster elevation-dataset elevation


  ask patches with [elevation = 0 ][set exit 1]
  ask patches [ifelse (elevation <= 0) or (elevation >= 0)[][set elevation 9999999]]

  show_elevation

 ;;create people
 ask n-of people patches with [elevation < 9999999 and exit != 1][sprout 1 [set color red set shape "square"]]

 ;;to show different colors in different areas
 ;ask turtles with [xcor < -5 and ycor > 5][set color yellow]
 ;ask turtles with [xcor < -5 and ycor < -5][set color green]
 ;ask turtles with [xcor >= -5][set color blue]

end


to go
  if count turtles > 0 [set move-speed count turtles with [moved? = true] / count turtles]
  if count turtles = 0 [print "the time taken:" print ticks reset-ticks stop]

  ask patches with [exit = 1] [ask turtles-here[die]]

  ask turtles [
    set moved? false
    let target min-one-of neighbors [ elevation + ( count turtles-here * 9999999) ]

    if [elevation + (count turtles-here * 9999999)] of target < [elevation] of patch-here
    [ face target
      move-to target
      set moved? true
      if UsePath? = false [ask target [set path path + 1]]]
  ]


      ;;if it can not move towards lower elevation, just move to a path where more people moved to (follow people)
    if UsePath? [ask turtles with [moved? = false][

    let target max-one-of neighbors [ path - ( count turtles-here * 9999999) ]

    if [path - (count turtles-here * 9999999)] of target > [path] of patch-here
    [ face target
      move-to target
      set moved? true
      ask target [set path path + 1]]
  ]]


  if Show_path? [ask patches with [elevation < 9999999][let thecolor (9.9 - (path * 0.15)) if thecolor < 0.001 [set thecolor 0.001] set pcolor thecolor]]

  tick
end


to crt-people

   ask n-of people patches with [elevation < 9999999 and exit != 1][sprout 1 [set color red set shape "square"]]

end

to move-right
  set heading 90
  fd 1
end

to move-down
  set heading 180
  fd 1
end

to move-up
  set heading 0
  fd 1
end

to draw-gridlines

let x min-pxcor
repeat world-width - 1 [
  crt 1 [
    set ycor min-pycor
    set xcor x + 0.5
    set color 0
    set heading 0
    pd
    fd world-height - 1
    die
  ]
      set x x + 1]

set x min-pycor
repeat world-height - 1[
  crt 1[
    set xcor min-pxcor
    set ycor x + 0.5
    set color 0
    set heading 90
    pd
    fd world-width - 1
    die

  ] set x x + 1]
end


to show_elevation
  let min-e min [elevation] of patches with [elevation < 9999999]
  let max-e max [elevation] of patches with [elevation < 9999999]

  ask patches [ifelse elevation < 9999999 [set pcolor scale-color blue elevation max-e min-e][set pcolor grey]]
end

to export_data

  file-close
  if file-exists? "data/result.asc" [ file-delete "data/result.asc"]
  file-open "data/result.asc"
  file-print "ncols         205   \r\n"
  file-print "nrows         129   \r\n"
  file-print "xllcorner     -122.26638888878   \r\n"
  file-print "yllcorner     42.855833333   \r\n"
  file-print  "cellsize      0.0011111111111859   \r\n"
  file-print  "NODATA_value  -9999   \r\n"

  let y max-pycor
  while [y >= 0 - max-pycor]
    [ let x 0 - max-pxcor
      while [x <= max-pxcor][
        ask patch x y [file-write path]

        set x x + 1]
      file-print " "
      set y y - 1

      ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
203
32
980
525
-1
-1
3.752
1
10
1
1
1
0
0
0
1
-102
102
-64
64
0
0
1
seconds
30.0

BUTTON
21
41
84
74
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
88
83
121
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
242
174
275
people
people
0
5000
1500.0
1
1
NIL
HORIZONTAL

BUTTON
102
87
165
120
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
18
292
174
325
Show_path?
Show_path?
0
1
-1000

BUTTON
19
148
169
181
show elevation graph
show_elevation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1039
37
1239
187
Number of people left
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

TEXTBOX
22
194
172
222
The darker the higher the \"elevation\" is.
11
0.0
1

PLOT
1038
223
1238
384
Average moving speed
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot move-speed"

BUTTON
1042
414
1175
447
export path graph
export_data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
1043
467
1193
495
Export the path frequency to an asc file.
11
0.0
1

CHOOSER
16
346
173
391
Number_of_exits
Number_of_exits
1 2
1

SWITCH
15
418
171
451
UsePath?
UsePath?
0
1
-1000

BUTTON
104
42
192
75
NIL
crt-people
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
21
464
171
570
Use path frequency map from last trial. After at least one trial, turn this on, click crt-people, and observe if the total time taken decreases. Also compare the plots.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of pedestrains who try to leave the floor through one or two exits. The map being used is from GMU's Krasnow Institute. The model records the frequency of each cell being chosen as a path and draws the result into a path graph, which can be exported to ArcGIS for further analysis.

Here is a graph showing the path graph opened in ArcGIS:

![Picture not found](file:data/path2.jpg)

## HOW IT WORKS

Each pacth has a variable called elevation, which is determined by (1) the shortest distance to the exit; (2)if it is in a room, elevation is lower being closer to gate. If there are more than one exit patches, the elevation is equal to the shortest distance to closest one of the exit patches.

People use the follow the gradient/ cost surface (always flow to lower elevation, if space is available) to move to the exit.

The model records the frequency of each patch being chosen as a path, and draws a "path frequency map".

When UsePath is turned on, people will move to a cell where the path frequency is higher, when they can not move to a cell with lower elevation.

## HOW TO USE IT

Basics:
1. Use the sliders to adjust the number of the exits and the number of people.
2. Press setup to load the floor plan, exit, and randomly distribute people on the floor.
3. Turn show_path? on to show the path frequency.
4. Press go to make people move 1 patch each tick, if path available.
5. Use the export function to export the path frequency graph to an asc file.

To use the path frequency map (frequency of being chosen as a path):
1. Run the model once wth UsePath off.
2. Turn UsePath on.
3. Use crt-people to create same amount of people as last run.
4. Run the model and observe if the time taken to clear decreases.

## EXTENDING THE MODEL

Can you add an obstacle in the middle of the room? How would that affect the result?

## NETLOGO FEATURES

In this model, the "elevation" of a patch is decided by its distance to exits as well as how close it is located to the gate of the room, so that people can run out if rooms. When running the model, people always try to move to lower elevation. This algorithm can also be used to build a rainfall model to analyze the movement of rain drops on the ground.

## RELATED MODELS

See the Grand Canyon in the NetLogo models library.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
