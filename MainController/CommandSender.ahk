#Requires AutoHotkey v2.0
; CommandSender.ahk - Отправитель команд
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "..\Shared\IPCProtocol.ahk"

class CommandSender {
    __New() {
        this.PendingCommands := Map()
        this.CommandTimeout := 10000  ; 10 секунд
    }
    
    ; Отправка команды скрипту
    SendCommand(ScriptName, CommandObj, Timeout := 0) {
        try {
            ; Генерируем уникальный ID команды
            if (!CommandObj.HasOwnProp("id")) {
                CommandObj.id := "cmd_" . A_TickCount . "_" . Random(1000, 9999)
            }
            
            ; Добавляем метаданные
            CommandObj.script := ScriptName
            CommandObj.timestamp := A_Now
            
            ; Находим окно целевого скрипта
            TargetWindow := this.FindScriptWindow(ScriptName)
            if (!TargetWindow) {
                throw Error("Не найдено окно скрипта: " . ScriptName)
            }
            
            ; Отправляем команду
            Result := IPCProtocol.SendData(TargetWindow, CommandObj)
            
            if (Result.Success) {
                ; Сохраняем команду для отслеживания таймаута
                if (Timeout > 0) {
                    this.PendingCommands[CommandObj.id] := {
                        Command: CommandObj,
                        SentTime: A_TickCount,
                        Timeout: Timeout
                    }
                }
                
                return {Success: true, CommandID: CommandObj.id}
            } else {
                return {Success: false, Error: Result.Error}
            }
            
        } catch as e {
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Поиск окна скрипта по имени
    FindScriptWindow(ScriptName) {
        ; Ищем окно с заголовком, содержащим имя скрипта
        WindowTitle := "IPC_" . ScriptName
        
        try {
            WindowID := WinExist(WindowTitle)
            return WindowID
        } catch {
            return 0
        }
    }
    
    ; Обработка таймаутов команд
    ProcessTimeouts() {
        CurrentTime := A_TickCount
        
        for CommandID, CommandInfo in this.PendingCommands {
            if (CurrentTime - CommandInfo.SentTime >= CommandInfo.Timeout) {
                ; Команда превысила таймаут
                this.OnCommandTimeout(CommandID, CommandInfo)
                this.PendingCommands.Delete(CommandID)
            }
        }
    }
    
    ; Обработчик таймаута команды
    OnCommandTimeout(CommandID, CommandInfo) {
        ; Здесь можно добавить логирование или уведомления
        ; о превышении таймаута команды
    }
    
    ; Обработка ответа на команду
    OnCommandResponse(CommandID, Response) {
        if (this.PendingCommands.Has(CommandID)) {
            this.PendingCommands.Delete(CommandID)
            ; Здесь можно добавить обработку ответа
        }
    }
}