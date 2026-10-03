// Reader's Night Filter for macOS: a crescent in the menu bar.
//
// The amber and the dimming are the screen's colour tables (the way f.lux does it): each
// channel's curve is multiplied by the 1900 K tint and by the brightness. macOS puts the
// tables back by itself when the app quits, even by a crash.
//
// Colour tables act on each channel alone, so they cannot make gray. The gray is the
// system's own grayscale (Accessibility › Display › Color Filters), switched by a
// CoreGraphics function Apple does not document. If this macOS no longer has it, the
// app says so and leaves the gray to that setting.
//
//   ReadersNight --self-test     checks the tables and the gray on this Mac, prints a report

import AppKit
import Carbon.HIToolbox
import ServiceManagement
import UserNotifications

// Amber: a black body at 1900 K, the coolest that has no blue (see tools/amber.py).
let tint: [CGGammaValue] = [1.0, 0.5167, 0.0]
let levels = [100, 90, 80, 70, 60, 50, 40, 30, 20, 15]
let shortcutName = "⌃⌥⌘N"
let appName = "Reader's Night Filter"

// MARK: - Words

let allStrings: [String: [String: String]] = [
    "en": [
        "on": "Night filter on",
        "off": "Night filter off",
        "lookGray": "Gray and amber, brightness %d %%",
        "lookColour": "Amber, brightness %d %%",
        "switch": "Night filter",
        "gray": "Gray before amber",
        "brightness": "Brightness",
        "notify": "Notifications",
        "schedule": "Schedule…",
        "scheduleSet": "Schedule: on at %@, off at %@…",
        "startup": "Open at login",
        "shortcut": "Keyboard shortcut: %@",
        "shortcutTaken": "Keyboard shortcut %@ is used by another app",
        "quit": "Quit Reader's Night Filter",
        "schedFollow": "Switch on and off at set times",
        "schedOn": "On at",
        "schedOff": "Off at",
        "ok": "OK",
        "cancel": "Cancel",
        "welcome": "Reader's Night Filter is running",
        "welcomeBody": "Its switch is the crescent in the menu bar, top right. %@ also switches it.",
        "failed": "The night filter could not be applied",
        "failedBody": "macOS refused the screen's colour tables.",
        "noGray": "The gray could not be applied",
        "noGrayBody": "This version of macOS did not accept it from the app. The amber and the dimming are on; the gray can be turned on in System Settings › Accessibility › Display › Color Filters.",
        "graySettings": "Turn on grayscale in System Settings…",
    ],
    "fr": [
        "on": "Filtre de nuit activé",
        "off": "Filtre de nuit désactivé",
        "lookGray": "Gris et ambre, luminosité %d %%",
        "lookColour": "Ambre, luminosité %d %%",
        "switch": "Filtre de nuit",
        "gray": "Gris avant l’ambre",
        "brightness": "Luminosité",
        "notify": "Notifications",
        "schedule": "Horaire…",
        "scheduleSet": "Horaire : activé à %@, désactivé à %@…",
        "startup": "Ouvrir à la connexion",
        "shortcut": "Raccourci clavier : %@",
        "shortcutTaken": "Le raccourci %@ est pris par une autre app",
        "quit": "Quitter Reader's Night Filter",
        "schedFollow": "Activer et désactiver à heures fixes",
        "schedOn": "Activé à",
        "schedOff": "Désactivé à",
        "ok": "OK",
        "cancel": "Annuler",
        "welcome": "Reader's Night Filter est lancé",
        "welcomeBody": "Son interrupteur est le croissant dans la barre des menus, en haut à droite. %@ l’active et le désactive aussi.",
        "failed": "Le filtre de nuit n’a pas pu être appliqué",
        "failedBody": "macOS a refusé les tables de couleur de l’écran.",
        "noGray": "Le gris n’a pas pu être appliqué",
        "noGrayBody": "Cette version de macOS ne l’a pas accepté de l’app. L’ambre et l’atténuation sont actifs ; le gris s’active dans Réglages Système › Accessibilité › Affichage › Filtres de couleur.",
        "graySettings": "Activer les niveaux de gris dans Réglages Système…",
    ],
    "de": [
        "on": "Nachtfilter ein",
        "off": "Nachtfilter aus",
        "lookGray": "Grau und Bernstein, Helligkeit %d %%",
        "lookColour": "Bernstein, Helligkeit %d %%",
        "switch": "Nachtfilter",
        "gray": "Grau vor Bernstein",
        "brightness": "Helligkeit",
        "notify": "Mitteilungen",
        "schedule": "Zeitplan…",
        "scheduleSet": "Zeitplan: ein um %@, aus um %@…",
        "startup": "Bei der Anmeldung öffnen",
        "shortcut": "Tastenkürzel: %@",
        "shortcutTaken": "Das Tastenkürzel %@ wird von einer anderen App verwendet",
        "quit": "Reader's Night Filter beenden",
        "schedFollow": "Zu festen Zeiten ein- und ausschalten",
        "schedOn": "Ein um",
        "schedOff": "Aus um",
        "ok": "OK",
        "cancel": "Abbrechen",
        "welcome": "Reader's Night Filter läuft",
        "welcomeBody": "Sein Schalter ist die Mondsichel in der Menüleiste oben rechts. Auch %@ schaltet ihn.",
        "failed": "Der Nachtfilter konnte nicht angewendet werden",
        "failedBody": "macOS hat die Farbtabellen des Bildschirms abgelehnt.",
        "noGray": "Das Grau konnte nicht angewendet werden",
        "noGrayBody": "Diese macOS-Version hat es von der App nicht angenommen. Bernstein und Dimmen sind aktiv; das Grau lässt sich unter Systemeinstellungen › Bedienungshilfen › Anzeige › Farbfilter einschalten.",
        "graySettings": "Graustufen in den Systemeinstellungen einschalten…",
    ],
    "es": [
        "on": "Filtro nocturno activado",
        "off": "Filtro nocturno desactivado",
        "lookGray": "Gris y ámbar, brillo %d %%",
        "lookColour": "Ámbar, brillo %d %%",
        "switch": "Filtro nocturno",
        "gray": "Gris antes del ámbar",
        "brightness": "Brillo",
        "notify": "Notificaciones",
        "schedule": "Horario…",
        "scheduleSet": "Horario: se activa a las %@, se desactiva a las %@…",
        "startup": "Abrir al iniciar sesión",
        "shortcut": "Atajo de teclado: %@",
        "shortcutTaken": "El atajo %@ lo usa otra app",
        "quit": "Salir de Reader's Night Filter",
        "schedFollow": "Activar y desactivar a horas fijas",
        "schedOn": "Se activa a las",
        "schedOff": "Se desactiva a las",
        "ok": "Aceptar",
        "cancel": "Cancelar",
        "welcome": "Reader's Night Filter está en marcha",
        "welcomeBody": "Su interruptor es la media luna de la barra de menús, arriba a la derecha. %@ también lo activa y desactiva.",
        "failed": "No se ha podido aplicar el filtro nocturno",
        "failedBody": "macOS ha rechazado las tablas de color de la pantalla.",
        "noGray": "No se ha podido aplicar el gris",
        "noGrayBody": "Esta versión de macOS no lo ha aceptado de la app. El ámbar y la atenuación están activos; el gris se activa en Ajustes del Sistema › Accesibilidad › Pantalla › Filtros de color.",
        "graySettings": "Activar la escala de grises en Ajustes del Sistema…",
    ],
    "pt": [
        "on": "Filtro noturno ligado",
        "off": "Filtro noturno desligado",
        "lookGray": "Cinzento e âmbar, brilho %d %%",
        "lookColour": "Âmbar, brilho %d %%",
        "switch": "Filtro noturno",
        "gray": "Cinzento antes do âmbar",
        "brightness": "Brilho",
        "notify": "Notificações",
        "schedule": "Horário…",
        "scheduleSet": "Horário: liga às %@, desliga às %@…",
        "startup": "Abrir ao iniciar sessão",
        "shortcut": "Atalho de teclado: %@",
        "shortcutTaken": "O atalho %@ é usado por outra app",
        "quit": "Sair do Reader's Night Filter",
        "schedFollow": "Ligar e desligar a horas fixas",
        "schedOn": "Liga às",
        "schedOff": "Desliga às",
        "ok": "OK",
        "cancel": "Cancelar",
        "welcome": "O Reader's Night Filter está em execução",
        "welcomeBody": "O seu interruptor é o crescente na barra de menus, em cima à direita. %@ também o liga e desliga.",
        "failed": "Não foi possível aplicar o filtro noturno",
        "failedBody": "O macOS recusou as tabelas de cor do ecrã.",
        "noGray": "Não foi possível aplicar o cinzento",
        "noGrayBody": "Esta versão do macOS não o aceitou da app. O âmbar e o escurecimento estão ativos; o cinzento ativa-se em Definições do Sistema › Acessibilidade › Ecrã › Filtros de cor.",
        "graySettings": "Ativar a escala de cinzentos nas Definições do Sistema…",
    ],
    "ru": [
        "on": "Ночной фильтр включён",
        "off": "Ночной фильтр выключен",
        "lookGray": "Серый и янтарный, яркость %d %%",
        "lookColour": "Янтарный, яркость %d %%",
        "switch": "Ночной фильтр",
        "gray": "Серый перед янтарным",
        "brightness": "Яркость",
        "notify": "Уведомления",
        "schedule": "Расписание…",
        "scheduleSet": "Расписание: включается в %@, выключается в %@…",
        "startup": "Открывать при входе в систему",
        "shortcut": "Сочетание клавиш: %@",
        "shortcutTaken": "Сочетание %@ занято другим приложением",
        "quit": "Завершить Reader's Night Filter",
        "schedFollow": "Включать и выключать в заданное время",
        "schedOn": "Включается в",
        "schedOff": "Выключается в",
        "ok": "ОК",
        "cancel": "Отменить",
        "welcome": "Reader's Night Filter запущен",
        "welcomeBody": "Его переключатель — полумесяц в строке меню, вверху справа. %@ тоже включает и выключает его.",
        "failed": "Не удалось применить ночной фильтр",
        "failedBody": "macOS отклонила цветовые таблицы экрана.",
        "noGray": "Не удалось применить серый",
        "noGrayBody": "Эта версия macOS не приняла его от приложения. Янтарный оттенок и затемнение включены; серый можно включить в Системных настройках › Универсальный доступ › Дисплей › Светофильтры.",
        "graySettings": "Включить оттенки серого в Системных настройках…",
    ],
]

let strings: [String: String] = {
    for language in Locale.preferredLanguages {
        if let table = allStrings[String(language.prefix(2))] { return table }
    }
    return allStrings["en"]!
}()

func tr(_ key: String, _ args: CVarArg...) -> String {
    let text = strings[key] ?? allStrings["en"]![key] ?? key
    return args.isEmpty ? text : String(format: text, arguments: args)
}

// MARK: - Settings

struct Settings {
    static let d = UserDefaults.standard

    static func register() {
        d.register(defaults: [
            "active": true, "gray": true, "brightness": 70, "notify": true,
            "schedule": false, "scheduleOn": "21:30", "scheduleOff": "07:00",
            "welcomed": false, "grayForcedByUs": false,
        ])
    }

    static var active: Bool { get { d.bool(forKey: "active") } set { d.set(newValue, forKey: "active") } }
    static var gray: Bool { get { d.bool(forKey: "gray") } set { d.set(newValue, forKey: "gray") } }
    static var brightness: Int {
        get { max(15, min(100, d.integer(forKey: "brightness"))) }
        set { d.set(newValue, forKey: "brightness") }
    }
    static var notify: Bool { get { d.bool(forKey: "notify") } set { d.set(newValue, forKey: "notify") } }
    static var schedule: Bool { get { d.bool(forKey: "schedule") } set { d.set(newValue, forKey: "schedule") } }
    static var scheduleOn: String { get { d.string(forKey: "scheduleOn")! } set { d.set(newValue, forKey: "scheduleOn") } }
    static var scheduleOff: String { get { d.string(forKey: "scheduleOff")! } set { d.set(newValue, forKey: "scheduleOff") } }
    static var welcomed: Bool { get { d.bool(forKey: "welcomed") } set { d.set(newValue, forKey: "welcomed") } }
    // Set while the system grayscale is on because this app turned it on, so that a
    // crash does not leave it on for good: the next start turns it off again.
    static var grayForcedByUs: Bool {
        get { d.bool(forKey: "grayForcedByUs") } set { d.set(newValue, forKey: "grayForcedByUs") }
    }
}

func minutes(_ hhmm: String) -> Int {
    let parts = hhmm.split(separator: ":").compactMap { Int($0) }
    return parts.count == 2 ? parts[0] * 60 + parts[1] : 0
}

// Is the clock inside the "on" span? The span may cross midnight.
func inSpan(_ date: Date, on: String, off: String) -> Bool {
    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
    let now = c.hour! * 60 + c.minute!, a = minutes(on), b = minutes(off)
    return a <= b ? (now >= a && now < b) : (now >= a || now < b)
}

// MARK: - The screen

enum Gray {
    private typealias SetFn = @convention(c) (Int32) -> Void
    private typealias GetFn = @convention(c) () -> Int32

    private static let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY)
    private static let setFn: SetFn? = symbol("CGDisplayForceToGray")
    private static let getFn: GetFn? = symbol("CGDisplayUsesForceToGray")

    private static func symbol<T>(_ name: String) -> T? {
        guard let h = handle, let p = dlsym(h, name) else { return nil }
        return unsafeBitCast(p, to: T.self)
    }

    static var available: Bool { setFn != nil && getFn != nil }
    static var isOn: Bool { (getFn?() ?? 0) != 0 }

    // Returns whether the screen is now as asked.
    @discardableResult
    static func set(_ on: Bool) -> Bool {
        guard let setFn = setFn else { return false }
        setFn(on ? 1 : 0)
        return isOn == on
    }
}

enum Tables {
    struct Curves: Equatable { var r, g, b: [CGGammaValue] }

    // What was set on each display, to notice when macOS has put its own back.
    static var applied: [CGDirectDisplayID: Curves] = [:]

    static func displays() -> [CGDirectDisplayID] {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(16, &ids, &count) == .success else { return [] }
        return Array(ids.prefix(Int(count)))
    }

    static func read(_ display: CGDirectDisplayID) -> Curves? {
        let capacity = CGDisplayGammaTableCapacity(display)
        guard capacity > 0 else { return nil }
        var r = [CGGammaValue](repeating: 0, count: Int(capacity))
        var g = r, b = r
        var n: UInt32 = 0
        guard CGGetDisplayTransferByTable(display, capacity, &r, &g, &b, &n) == .success, n > 0 else { return nil }
        let k = Int(n)
        return Curves(r: Array(r.prefix(k)), g: Array(g.prefix(k)), b: Array(b.prefix(k)))
    }

    // Puts back the system's own curves, then multiplies them by the tint and the
    // brightness. Returns false if a display refused.
    static func apply(brightness: Int) -> Bool {
        CGDisplayRestoreColorSyncSettings()
        applied = [:]
        let dim = CGGammaValue(brightness) / 100
        var ok = true
        for display in displays() {
            guard let base = read(display) else { ok = false; continue }
            let curves = Curves(r: base.r.map { $0 * tint[0] * dim },
                                g: base.g.map { $0 * tint[1] * dim },
                                b: base.b.map { $0 * tint[2] * dim })
            let result = CGSetDisplayTransferByTable(display, UInt32(curves.r.count), curves.r, curves.g, curves.b)
            if result == .success { applied[display] = curves } else { ok = false }
        }
        return ok && !applied.isEmpty
    }

    static func clear() {
        applied = [:]
        CGDisplayRestoreColorSyncSettings()
    }

    // Still on screen as set? Off by a little is still as set: the system may round.
    static func intact() -> Bool {
        let now = displays()
        if Set(now) != Set(applied.keys) { return false }
        for display in now {
            guard let want = applied[display], let have = read(display), have.r.count == want.r.count else { return false }
            for i in stride(from: 0, to: want.r.count, by: max(1, want.r.count / 16)) {
                if abs(have.r[i] - want.r[i]) > 0.01 || abs(have.g[i] - want.g[i]) > 0.01 || abs(have.b[i] - want.b[i]) > 0.01 {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - The app

final class App: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    static let shared = App()

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let menu = NSMenu()
    var hotKey: EventHotKeyRef?
    var hotKeyRegistered = false
    var lastSpan = false
    var tintFailureShown = false
    var grayFailed = false
    var keepTimer: Timer?
    var clockTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.register()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }

        // A crash left the system grayscale on: it was ours, take it back.
        if Settings.grayForcedByUs && !(Settings.active && Settings.gray) {
            Gray.set(false)
            Settings.grayForcedByUs = false
        }

        menu.delegate = self
        statusItem.menu = menu
        registerHotKey()

        if Settings.schedule {
            lastSpan = inSpan(Date(), on: Settings.scheduleOn, off: Settings.scheduleOff)
            Settings.active = lastSpan
        }
        apply()
        updateIcon()

        if !Settings.welcomed {
            Settings.welcomed = true
            try? SMAppService.mainApp.register()
            post(id: "welcome", tr("welcome"), tr("welcomeBody", shortcutName))
        }

        keepTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in self.reassert() }
        clockTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in self.followSchedule() }

        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification,
                     NSWorkspace.sessionDidBecomeActiveNotification] {
            workspace.addObserver(forName: name, object: nil, queue: .main) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.followSchedule()
                    if Settings.active { self.apply() }
                }
            }
        }
        CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
            if flags.contains(.beginConfigurationFlag) { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if Settings.active { App.shared.apply() }
            }
        }, nil)
    }

    // Opening the app again from the Finder or Launchpad while it runs: the switch.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggle()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        Tables.clear()
        releaseGray()
    }

    // MARK: the filter

    func apply() {
        if Settings.active {
            let ok = Tables.apply(brightness: Settings.brightness)
            if !ok && !tintFailureShown {
                tintFailureShown = true
                post(id: "failed", tr("failed"), tr("failedBody"))
            }
            if ok { tintFailureShown = false }
            applyGray()
        } else {
            Tables.clear()
            releaseGray()
        }
    }

    func applyGray() {
        if !Settings.gray { releaseGray(); return }
        if Gray.isOn { return }  // already gray, whoever turned it on
        if Gray.set(true) {
            Settings.grayForcedByUs = true
            grayFailed = false
        } else if !grayFailed {
            grayFailed = true
            post(id: "noGray", tr("noGray"), tr("noGrayBody"))
        }
    }

    // Turns the system grayscale off only if this app turned it on.
    func releaseGray() {
        guard Settings.grayForcedByUs else { return }
        Gray.set(false)
        Settings.grayForcedByUs = false
    }

    // macOS puts its own tables back after some changes (a display waking, ColorSync);
    // they are set again when what is on screen is not what was asked.
    func reassert() {
        guard Settings.active else { return }
        if !Tables.intact() { apply() }
        else if Settings.gray && Settings.grayForcedByUs && !Gray.isOn { applyGray() }
    }

    func switchTo(_ on: Bool) {
        guard Settings.active != on else { return }
        Settings.active = on
        apply()
        updateIcon()
        announce()
    }

    @objc func toggle() { switchTo(!Settings.active) }

    func announce() {
        guard Settings.notify else { return }
        let look = tr(Settings.gray ? "lookGray" : "lookColour", Settings.brightness)
        post(id: "state", tr(Settings.active ? "on" : "off"), Settings.active ? look : "")
    }

    func post(id: String, _ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // The app has no window, so macOS counts it as in front: show the banner anyway.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }

    func updateIcon() {
        let name = Settings.active ? "moon.fill" : "moon"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: appName)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = appName + " — " + tr(Settings.active ? "on" : "off")
    }

    // MARK: the schedule: on at the first time, off at the second

    func followSchedule() {
        guard Settings.schedule else { return }
        let span = inSpan(Date(), on: Settings.scheduleOn, off: Settings.scheduleOff)
        if span != lastSpan {
            lastSpan = span
            switchTo(span)
        }
    }

    @objc func editSchedule() {
        let alert = NSAlert()
        alert.messageText = appName
        alert.addButton(withTitle: tr("ok"))
        alert.addButton(withTitle: tr("cancel"))

        let follow = NSButton(checkboxWithTitle: tr("schedFollow"), target: nil, action: nil)
        follow.state = Settings.schedule ? .on : .off
        let on = timePicker(Settings.scheduleOn), off = timePicker(Settings.scheduleOff)
        let rows = NSGridView(views: [
            [NSTextField(labelWithString: tr("schedOn")), on],
            [NSTextField(labelWithString: tr("schedOff")), off],
        ])
        rows.rowSpacing = 8
        rows.columnSpacing = 12
        let stack = NSStackView(views: [follow, rows])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.frame = NSRect(x: 0, y: 0, width: 320, height: 90)
        alert.accessoryView = stack

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Settings.schedule = follow.state == .on
        Settings.scheduleOn = hhmm(on.dateValue)
        Settings.scheduleOff = hhmm(off.dateValue)
        if Settings.schedule {
            lastSpan = inSpan(Date(), on: Settings.scheduleOn, off: Settings.scheduleOff)
            switchTo(lastSpan)
        }
    }

    func timePicker(_ value: String) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = .hourMinute
        picker.dateValue = Calendar.current.date(bySettingHour: minutes(value) / 60, minute: minutes(value) % 60,
                                                 second: 0, of: Date()) ?? Date()
        return picker
    }

    func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour!, c.minute!)
    }

    // MARK: the menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let main = item(tr("switch"), #selector(toggle), on: Settings.active)
        main.attributedTitle = NSAttributedString(string: tr("switch"),
                                                  attributes: [.font: NSFont.menuFont(ofSize: 0).bold()])
        main.keyEquivalent = "n"
        main.keyEquivalentModifierMask = [.control, .option, .command]
        menu.addItem(main)
        menu.addItem(.separator())

        menu.addItem(item(tr("gray"), #selector(toggleGray), on: Settings.gray))
        if grayFailed && Settings.gray {
            menu.addItem(item(tr("graySettings"), #selector(openGraySettings)))
        }

        let brightness = NSMenuItem(title: tr("brightness"), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for level in levels {
            let it = item("\(level) %", #selector(setBrightness(_:)), on: Settings.brightness == level)
            it.tag = level
            sub.addItem(it)
        }
        brightness.submenu = sub
        menu.addItem(brightness)

        menu.addItem(item(tr("notify"), #selector(toggleNotify), on: Settings.notify))
        let schedText = Settings.schedule
            ? tr("scheduleSet", Settings.scheduleOn, Settings.scheduleOff) : tr("schedule")
        menu.addItem(item(schedText, #selector(editSchedule)))
        menu.addItem(item(tr("startup"), #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled))

        menu.addItem(.separator())
        let shortcut = NSMenuItem(title: tr(hotKeyRegistered ? "shortcut" : "shortcutTaken", shortcutName),
                                  action: nil, keyEquivalent: "")
        shortcut.isEnabled = false
        menu.addItem(shortcut)
        menu.addItem(.separator())
        menu.addItem(item(tr("quit"), #selector(NSApplication.terminate(_:)), target: NSApp))
    }

    func item(_ title: String, _ action: Selector, on: Bool? = nil, target: AnyObject? = nil) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: "")
        it.target = target ?? self
        if let on = on { it.state = on ? .on : .off }
        return it
    }

    // A setting of the look changed: shown at once if the filter is on, and announced.
    func changed() {
        guard Settings.active else { return }
        apply()
        announce()
    }

    @objc func toggleGray() { Settings.gray.toggle(); changed() }
    @objc func setBrightness(_ sender: NSMenuItem) { Settings.brightness = sender.tag; changed() }
    @objc func toggleNotify() { Settings.notify.toggle() }

    @objc func toggleLogin() {
        let service = SMAppService.mainApp
        if service.status == .enabled { try? service.unregister() }
        else {
            try? service.register()
            if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        }
    }

    @objc func openGraySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Display")!
        NSWorkspace.shared.open(url)
    }

    // MARK: the keyboard shortcut, Carbon's: the one that needs no permission

    func registerHotKey() {
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { App.shared.toggle() }
            return noErr
        }, 1, &type, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x524E_4654), id: 1)  // "RNFT"
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(controlKey | optionKey | cmdKey), id,
                                         GetApplicationEventTarget(), 0, &hotKey)
        hotKeyRegistered = status == noErr
    }
}

extension NSFont {
    func bold() -> NSFont { NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask) }
}

// MARK: - Self-test

func selfTest() -> Int32 {
    var failed = false
    func check(_ what: String, _ ok: Bool) {
        print((ok ? "ok   " : "FAIL ") + what)
        if !ok { failed = true }
    }
    func note(_ what: String) { print("     " + what) }

    note("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    let displays = Tables.displays()
    note("\(displays.count) display(s): " + displays.map { "\($0)" }.joined(separator: ", "))
    for d in displays {
        note("display \(d): table capacity \(CGDisplayGammaTableCapacity(d)), builtin \(CGDisplayIsBuiltin(d) != 0)")
    }

    let tablesOK = Tables.apply(brightness: 70)
    note("tables set at 70 %: \(tablesOK)")
    note("tables read back as set: \(Tables.intact())")
    if let d = displays.first, let c = Tables.read(d), let last = c.r.indices.last {
        note(String(format: "white now (%.3f, %.3f, %.3f), expected about (0.700, 0.362, 0.000)",
                    c.r[last], c.g[last], c.b[last]))
    }
    Tables.clear()

    note("grayscale functions found: \(Gray.available)")
    if Gray.available {
        let before = Gray.isOn
        note("grayscale on before: \(before)")
        let on = Gray.set(true)
        note("grayscale switched on and reported on: \(on)")
        let off = Gray.set(before)
        note("grayscale put back: \(off)")
    }

    check("schedule across midnight",
          inSpan(at(23, 0), on: "21:30", off: "07:00") && inSpan(at(6, 59), on: "21:30", off: "07:00")
          && !inSpan(at(12, 0), on: "21:30", off: "07:00") && !inSpan(at(7, 0), on: "21:30", off: "07:00"))
    check("schedule within a day", inSpan(at(9, 0), on: "08:00", off: "18:00") && !inSpan(at(19, 0), on: "08:00", off: "18:00"))
    check("no blue in the tint", tint[2] == 0)
    print(failed ? "something failed" : "done")
    return failed ? 1 : 0
}

func at(_ hour: Int, _ minute: Int) -> Date {
    Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
}

// MARK: - Start

if CommandLine.arguments.contains("--self-test") {
    exit(selfTest())
}

// One copy at a time: a second start switches the filter of the first and quits.
let running = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if !running.isEmpty {
    DistributedNotificationCenter.default().postNotificationName(
        .init("ch.gallaz.readersnight.toggle"), object: nil, userInfo: nil, deliverImmediately: true)
    exit(0)
}
DistributedNotificationCenter.default().addObserver(
    forName: .init("ch.gallaz.readersnight.toggle"), object: nil, queue: .main) { _ in App.shared.toggle() }

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
application.delegate = App.shared
application.run()
