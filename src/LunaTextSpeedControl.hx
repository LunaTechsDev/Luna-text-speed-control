import core.Types.JsFn;
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

  Comment.title("Window_Message");
  var _winMsgInit: JsFn = Fn.proto(Window_Message).initializeR;
  #if compileMV
  Fn.proto(Window_Message).initializeD = () -> {
   _winMsgInit.call(Fn.self);
   untyped Fn.self.originalTextSpeed = LunaTextSpeedControl.textSpeed;
   untyped Fn.self.activeTextSpeed = LunaTextSpeedControl.textSpeed;
  }
  #else
  Fn.proto(Window_Message).initializeD = (rect: Rectangle) -> {
   _winMsgInit.call(Fn.self, rect);
   untyped Fn.self.originalTextSpeed = LunaTextSpeedControl.textSpeed;
   untyped Fn.self.activeTextSpeed = LunaTextSpeedControl.textSpeed;
  }
  #end

  untyped {
   Fn.proto(Window_Message).updateTextSpeed = (value) -> {
    Fn.self.activeTextSpeed = value;
   }
  }

  var _winMsgProcessEscapeCharacter: JsFn = Fn.proto(Window_Message)
   .processEscapeCharacterR;
  Fn.proto(Window_Message)
   .processEscapeCharacterD = (code: String, textState: String) -> {
    var winMsg: Window_Message = Fn.self;
    switch (code) {
     case 'TS':
      untyped winMsg.updateTextSpeed(winMsg.obtainEscapeParam(textState).int());
     case _:
      _winMsgProcessEscapeCharacter.call(winMsg, code, textState);
    }
   } #if compileMV

  var _winMsgProcessNormCharacter: JsFn = Fn.proto(Window_Message)
   .processNormalCharacterR;
  Fn.proto(Window_Message).processNormalCharacterD = (textState: TextState) -> {
   // super.processNormalCharacter(textState);
   _winMsgProcessNormCharacter.call(Fn.self, textState);
   var winMsg: Window_Message = Fn.self;
   var char = textState.text.charAt(textState.index);
   if (winMsg.__lineShowFast == false && winMsg.__showFast == false
    && !char.isControlCharacter(0))
    untyped winMsg.startWait(winMsg.activeTextSpeed);
  }
  #else
  var _winProcessCharacter: JsFn = Fn.proto(Window_Message).processCharacterR;
  Fn.proto(Window_Message).processCharacterD = (textState: TextState) -> {
   // super.processCharacter(textState);
   var winMsg: Window_Message = Fn.self;
   _winProcessCharacter.call(winMsg, textState);
   var char = textState.text.charAt(textState.index);
   trace(char.isControlCharacter(0));
   if (winMsg.__lineShowFast == false && winMsg.__showFast == false
    && !char.isControlCharacter(0)) {
    untyped winMsg.startWait(winMsg.activeTextSpeed);
   }
  }
  #end

  var _updateWait: JsFn = Fn.proto(Window_Message).updateWaitR;
  Fn.proto(Window_Message).updateWaitD = () -> {
   untyped if (Fn.self.isTriggered() && LunaTextSpeedControl.allowSkip) {
    untyped Fn.self._waitCount = 0;
    untyped Fn.self._showFast = true;
   }
   return _updateWait.call(Fn.self);
  }

  var _winMsgTerminateMessage: JsFn = Fn.proto(Window_Message)
   .terminateMessageR;
  Fn.proto(Window_Message).terminateMessageD = () -> {
   untyped Fn.self.activeTextSpeed = Fn.self.originalTextSpeed;
   _winMsgTerminateMessage.call(Fn.self);
  }

  // var newWinMsg = Fn.renameClass(Window_Message, MessageWinNew);
 }
}
