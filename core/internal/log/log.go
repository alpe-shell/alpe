package log

import (
	"github.com/alpe-shell/alpe/core/internal/brand"
	duxlog "github.com/duxlabs-dev/dux-go/log"
)

type Logger = duxlog.Logger

func init() {
	// ALPE_LOG_LEVEL, ALPE_LOG_FILE … wie in der Oberfläche (Services/Log.qml)
	duxlog.SetEnvPrefix(brand.EnvPrefix)
}

func GetLogger() *Logger { return duxlog.GetLogger() }

func GetQtLoggingRules() string { return duxlog.GetQtLoggingRules() }

func SetLevel(level string) { duxlog.SetLevel(level) }

func SetLogFile(path string) error { return duxlog.SetLogFile(path) }

func ApplyEnvOverrides() { duxlog.ApplyEnvOverrides() }

func Debug(msg any, keyvals ...any)  { duxlog.Debug(msg, keyvals...) }
func Debugf(format string, v ...any) { duxlog.Debugf(format, v...) }
func Info(msg any, keyvals ...any)   { duxlog.Info(msg, keyvals...) }
func Infof(format string, v ...any)  { duxlog.Infof(format, v...) }
func Warn(msg any, keyvals ...any)   { duxlog.Warn(msg, keyvals...) }
func Warnf(format string, v ...any)  { duxlog.Warnf(format, v...) }
func Error(msg any, keyvals ...any)  { duxlog.Error(msg, keyvals...) }
func Errorf(format string, v ...any) { duxlog.Errorf(format, v...) }
func Fatal(msg any, keyvals ...any)  { duxlog.Fatal(msg, keyvals...) }
func Fatalf(format string, v ...any) { duxlog.Fatalf(format, v...) }
