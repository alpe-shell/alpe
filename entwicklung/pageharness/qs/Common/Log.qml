pragma Singleton
import QtQuick
QtObject { function scoped(n) { return { warn: function() { console.log("LOGWARN", Array.prototype.join.call(arguments, " ")) }, debug: function() {}, info: function() {} } } }
