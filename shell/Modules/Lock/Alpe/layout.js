.pragma library
// Erzeugt von tools/hyprlock2qml.py aus lockscreen/hyprlock.conf.
// Nicht von Hand ändern: Die Quelle ist die hyprlock.conf.
var layout = {
 "general": {
  "ignoreEmptyInput": true,
  "hideCursor": false
 },
 "background": {
  "path": "",
  "source": "desktop",
  "image": "",
  "color": "#ff111111",
  "blurPasses": 3,
  "blurSize": 7.0,
  "noise": 0.0117,
  "contrast": 0.8916,
  "brightness": 0.7172,
  "vibrancy": 0.1696,
  "vibrancyDarkness": 0.0
 },
 "widgets": [
  {
   "position": [
    "0",
    "-350"
   ],
   "monitor": "",
   "halign": "center",
   "valign": "top",
   "zindex": 5,
   "rotate": 0,
   "opacity": 1.0,
   "type": "label",
   "text": "{date:%H}",
   "update": 1000,
   "color": "#bfffffff",
   "fontSize": 150.0,
   "font": {
    "family": "AlfaSlabOne",
    "weight": 400,
    "italic": false
   },
   "align": "center",
   "shadow": {
    "size": 3.0,
    "passes": 0,
    "color": "#ff000000",
    "boost": 1.2
   },
   "order": 0
  },
  {
   "position": [
    "0",
    "-520"
   ],
   "monitor": "eDP-1",
   "halign": "center",
   "valign": "top",
   "zindex": 5,
   "rotate": 0,
   "opacity": 1.0,
   "type": "label",
   "text": "{date:%M}",
   "update": 1000,
   "color": "#bfffffff",
   "fontSize": 150.0,
   "font": {
    "family": "AlfaSlabOne",
    "weight": 400,
    "italic": false
   },
   "align": "center",
   "shadow": {
    "size": 0,
    "passes": 0,
    "color": "#ff000000",
    "boost": 1.2
   },
   "order": 1
  },
  {
   "position": [
    "0",
    "20"
   ],
   "monitor": "eDP-1",
   "halign": "center",
   "valign": "center",
   "zindex": 5,
   "rotate": 0,
   "opacity": 1.0,
   "type": "label",
   "text": "{date:%A, %d. %B}",
   "update": 1000,
   "color": "#ffffffff",
   "fontSize": 24.0,
   "font": {
    "family": "JetBrains Mono Nerd Font Mono",
    "weight": 400,
    "italic": false
   },
   "align": "center",
   "shadow": {
    "size": 0,
    "passes": 0,
    "color": "#ff000000",
    "boost": 1.2
   },
   "order": 2
  },
  {
   "position": [
    "0",
    "-40"
   ],
   "monitor": "eDP-1",
   "halign": "center",
   "valign": "center",
   "zindex": 20,
   "rotate": 0,
   "opacity": 1.0,
   "type": "input",
   "size": [
    "200",
    "50"
   ],
   "outline": 1.0,
   "outerColor": "#00ffffff",
   "innerColor": "#1affffff",
   "fontColor": "#ffc8c8c8",
   "fontFamily": "Sans",
   "checkColor": "#ffcc8822",
   "failColor": "#ffcc2222",
   "capslockColor": "",
   "dotsSize": 0.1,
   "dotsSpacing": 1.0,
   "dotsCenter": true,
   "dotsRounding": -1,
   "hideInput": false,
   "fadeOnEmpty": false,
   "rounding": -1,
   "placeholder": "Passwort...",
   "failText": "<i>{FAIL} <b>({ATTEMPTS})</b></i>",
   "failTimeout": 2000,
   "order": 3
  }
 ],
 "reference": {
  "width": 2560,
  "height": 1664
 },
 "source": "lockscreen/hyprlock.conf"
};
