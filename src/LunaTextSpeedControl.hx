import rm.core.Input;
import rm.types.RM.TextState;
import rm.Globals;
import rm.core.Rectangle;
import macros.MacroTools;
import rm.windows.Window_Message;
import rm.managers.PluginManager;
import utils.Fn;
import utils.Comment;
import rm.windows.Window_Message;
import rm.sprites.Sprite_Base;

using Std;
using StringTools;
using core.StringExtensions;

class LunaTextSpeedControl {
 public static var textSpeed: Int = 2;
 public static var allowSkip: Bool = true;

 public static function main() {
  var parameters: Any = Globals.Plugins.filter((plugin) ->
   ~/<LunaTxtSpeedCntrl>/ig.match(plugin.description))[0].parameters;
  textSpeed = cast Fn.parseIntJs(Fn.getByArrSyntax(parameters, "Text Speed"),
   10);
  allowSkip = Fn.getByArrSyntax(parameters, "Allow Show Fast During Wait")
   .trim() == "true";
  trace(textSpeed);
  trace(allowSkip);

  var newWinMsg = Fn.renameClass(Window_Message, MessageWinNew);
 }
}

@:keep
class MessageWinNew extends Window_Message {
 public var activeTextSpeed: Int;
 public var originalTextSpeed: Int;

 #if compileMV
 public function new(x, y, width, height) {
  super(x, y, width, height);
  this.originalTextSpeed = LunaTextSpeedControl.textSpeed;
  this.activeTextSpeed = LunaTextSpeedControl.textSpeed;
 }
 #else
 public function new(rect: Rectangle) {
  super(rect);
  this.originalTextSpeed = LunaTextSpeedControl.textSpeed;
  this.activeTextSpeed = LunaTextSpeedControl.textSpeed;
 }
 #end

 public function updateTextSpeed(value) {
  this.activeTextSpeed = value;
 }

 public override function processEscapeCharacter(code: String,
   textState: String) {
  switch (code) {
   case '$':
    this._goldWindow.open();
   case '.':
    this.startWait(15);
   case '|':
    this.startWait(60);
   case '!':
    this.startPause();

   case '>':
    this._lineShowFast = true;

   case '<':
    this._lineShowFast = false;

   case '^':
    this._pauseSkip = true;

   case 'TS':
    this.updateTextSpeed(this.obtainEscapeParam(textState).int());
   case _:
    super.processEscapeCharacter(code, textState);
  }
 }

 #if compileMV
 public override function processNormalCharacter(textState: TextState) {
  super.processNormalCharacter(textState);
  if (this._lineShowFast == false && this._showFast == false)
   this.startWait(this.activeTextSpeed);
 }
 #else
 public override function processCharacter(textState: TextState) {
  super.processCharacter(textState);
  var char = textState.text.charAt(textState.index);
  trace(char.isControlCharacter(0));
  if (this._lineShowFast == false && this._showFast == false
   && !char.isControlCharacter(0)) {
   this.startWait(this.activeTextSpeed);
  }
 }
 #end

 public override function updateWait() {
  if (this.isTriggered() && LunaTextSpeedControl.allowSkip) {
   this._waitCount = 0;
   this._showFast = true;
  }
  return super.updateWait();
 }

 public override function terminateMessage() {
  this.activeTextSpeed = this.originalTextSpeed;
  super.terminateMessage();
 }
}
