#Requires AutoHotkey v2.0
; HotkeyManager.ahk - Менеджер горячих клавиш
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class HotkeyManager {
    __New() {
        this.RegisteredHotkeys := []
        this.IsInitialized := false
    }
    
    Initialize() {
        try {
            ; Регистрируем горячие клавиши
            this.RegisterHotkey("F1", () => this.OnProcessHotkey())
            this.RegisterHotkey("F2", () => this.OnRestoreHotkey())
            
            this.IsInitialized := true
            
        } catch as e {
            ; Ошибка регистрации горячих клавиш
        }
    }
    
    RegisterHotkey(Key, Callback) {
        try {
            Hotkey(Key, Callback)
            this.RegisteredHotkeys.Push(Key)
        } catch {
            ; Ошибка регистрации
        }
    }
    
    Cleanup() {
        for Key in this.RegisteredHotkeys {
            try {
                Hotkey(Key, "Off")
            } catch {
                ; Игнорируем ошибки
            }
        }
        this.RegisteredHotkeys := []
        this.IsInitialized := false
    }
    
    OnProcessHotkey() {
        ; Обработка нажатия F1
    }
    
    OnRestoreHotkey() {
        ; Обработка нажатия F2
    }
}