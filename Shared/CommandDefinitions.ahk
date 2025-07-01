#Requires AutoHotkey v2.0
; CommandDefinitions.ahk - Определения команд IPC
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class CommandDefinitions {
    ; Команды управления
    static SHUTDOWN := "SHUTDOWN"
    static GET_STATUS := "GET_STATUS"
    static TOGGLE_PAUSE := "TOGGLE_PAUSE"
    
    ; Команды WordProcessor
    static START_PROCESSING := "START_PROCESSING"
    static STOP_PROCESSING := "STOP_PROCESSING"
    static RESTORE_FILES := "RESTORE_FILES"
    
    ; Ответы
    static STATUS_RESPONSE := "STATUS_RESPONSE"
    static COMMAND_RESULT := "COMMAND_RESULT"
    static ERROR_RESPONSE := "ERROR_RESPONSE"
    
    ; Создание команды
    static CreateCommand(command, params := "") {
        return {
            command: command,
            params: params,
            timestamp: A_Now,
            id: "cmd_" . A_TickCount . "_" . Random(1000, 9999)
        }
    }
    
    ; Создание ответа
    static CreateResponse(commandId, result, data := "") {
        return {
            command: CommandDefinitions.COMMAND_RESULT,
            commandId: commandId,
            result: result,
            data: data,
            timestamp: A_Now
        }
    }
}