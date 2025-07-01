#Requires AutoHotkey v2.0
; IPCProtocol.ahk - Протокол межпроцессного взаимодействия
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "JSONHelper.ahk"

class IPCProtocol {
    static WM_COPYDATA := 0x004A
    
    ; Отправка команды процессу
    static SendCommand(TargetPID, CommandObj) {
        ; Находим главное окно процесса
        TargetWindow := IPCProtocol.FindProcessWindow(TargetPID)
        if (!TargetWindow) {
            return {Success: false, Error: "Не найдено окно процесса"}
        }
        
        return IPCProtocol.SendData(TargetWindow, CommandObj)
    }
    
    ; Отправка данных окну
    static SendData(TargetWindow, DataObj) {
        try {
            ; Преобразуем объект в JSON
            JSONData := JSONHelper.Stringify(DataObj)
            
            ; Создаем структуру COPYDATASTRUCT
            DataSize := StrLen(JSONData) * 2  ; UTF-16
            
            ; Отправляем сообщение
            Result := SendMessage(IPCProtocol.WM_COPYDATA, 0, 
                IPCProtocol.CreateCopyDataStruct(1, DataSize, JSONData), 
                TargetWindow)
            
            if (Result) {
                return {Success: true}
            } else {
                return {Success: false, Error: "Не удалось отправить сообщение"}
            }
            
        } catch as e {
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Получение данных из сообщения WM_COPYDATA
    static ReceiveData(wParam, lParam) {
        try {
            ; Читаем структуру COPYDATASTRUCT
            dwData := NumGet(lParam, 0, "UPtr")
            cbData := NumGet(lParam, A_PtrSize, "UPtr")
            lpData := NumGet(lParam, A_PtrSize * 2, "UPtr")
            
            if (cbData > 0 && lpData) {
                ; Читаем строку
                JSONData := StrGet(lpData, cbData // 2, "UTF-16")
                
                ; Парсим JSON
                DataObj := JSONHelper.Parse(JSONData)
                
                return {Success: true, Data: DataObj}
            }
            
            return {Success: false, Error: "Нет данных"}
            
        } catch as e {
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Создание структуры COPYDATASTRUCT
    static CreateCopyDataStruct(dwData, cbData, lpData) {
        ; Выделяем память для структуры
        Struct := Buffer(A_PtrSize * 3)
        
        ; Заполняем структуру
        NumPut("UPtr", dwData, Struct, 0)
        NumPut("UPtr", cbData, Struct, A_PtrSize)
        NumPut("UPtr", StrPtr(lpData), Struct, A_PtrSize * 2)
        
        return Struct
    }
    
    ; Поиск главного окна процесса
    static FindProcessWindow(PID) {
        MainWindow := 0
        
        ; Перебираем все окна
        WinGet("List", "OutputVar")
        
        Loop OutputVar {
            WindowID := OutputVar%A_Index%
            
            ; Проверяем PID окна
            WinGet("PID", "WindowPID", "ahk_id " . WindowID)
            
            if (WindowPID == PID) {
                ; Проверяем, что это главное окно
                if (WinGetExStyle("ahk_id " . WindowID) & 0x00000008) {  ; WS_EX_TOPMOST
                    continue
                }
                
                MainWindow := WindowID
                break
            }
        }
        
        return MainWindow
    }
    
    ; Создание IPC окна для получения сообщений
    static CreateIPCWindow(WindowTitle) {
        ; Создаем скрытое окно для IPC
        IPCGui := Gui("+LastFound -MaximizeBox -MinimizeBox", WindowTitle)
        IPCGui.Show("Hide")
        
        return IPCGui
    }
}