#Requires AutoHotkey v2.0
; Logger.ahk - Система логирования
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class Logger {
    __New() {
        this.LogFile := A_ScriptDir . "\errors.log"
        this.MaxLogSize := 1048576  ; 1MB
    }
    
    Log(Message) {
        this.WriteLog("[INFO] " . Message)
    }
    
    Error(Message) {
        this.WriteLog("[ERROR] " . Message)
    }
    
    Warning(Message) {
        this.WriteLog("[WARNING] " . Message)
    }
    
    WriteLog(Message) {
        try {
            ; Проверяем размер лога
            if (FileExist(this.LogFile)) {
                FileInfo := FileGetSize(this.LogFile)
                if (FileInfo > this.MaxLogSize) {
                    this.RotateLog()
                }
            }
            
            FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            LogEntry := "[" . FormattedTime . "] " . Message . "`n"
            
            FileAppend(LogEntry, this.LogFile, "UTF-8")
            
        } catch {
            ; Игнорируем ошибки записи
        }
    }
    
    RotateLog() {
        try {
            BackupFile := StrReplace(this.LogFile, ".log", "_backup.log")
            if (FileExist(BackupFile)) {
                FileDelete(BackupFile)
            }
            FileMove(this.LogFile, BackupFile)
        } catch {
            ; Игнорируем ошибки ротации
        }
    }
}