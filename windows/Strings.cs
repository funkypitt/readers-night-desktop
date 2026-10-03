// What the app says, in the six languages of the Reader's apps.

using System.Collections.Generic;
using System.Globalization;

namespace ReadersNight
{
    static class Strings
    {
        public const string AppName = "Reader's Night Filter";

        static readonly Dictionary<string, Dictionary<string, string>> All = new Dictionary<string, Dictionary<string, string>>
        {
            ["en"] = new Dictionary<string, string>
            {
                ["on"] = "Night filter on",
                ["off"] = "Night filter off",
                ["lookGray"] = "Gray and amber, brightness {0} %",
                ["lookColour"] = "Amber, brightness {0} %",
                ["switch"] = "Night filter",
                ["gray"] = "Gray before amber",
                ["brightness"] = "Brightness",
                ["notify"] = "Notifications",
                ["schedule"] = "Schedule…",
                ["scheduleSet"] = "Schedule: on at {0}, off at {1}…",
                ["startup"] = "Start with Windows",
                ["shortcut"] = "Keyboard shortcut: {0}",
                ["shortcutTaken"] = "Keyboard shortcut {0} is used by another program",
                ["quit"] = "Quit",
                ["schedFollow"] = "Switch on and off at set times",
                ["schedOn"] = "On at",
                ["schedOff"] = "Off at",
                ["ok"] = "OK",
                ["cancel"] = "Cancel",
                ["welcome"] = "Reader's Night Filter is running",
                ["welcomeBody"] = "Its switch is the crescent in the notification area, bottom right (under the ^ arrow if Windows hid it). {0} also switches it.",
                ["failed"] = "The night filter could not be applied",
                ["failedBody"] = "Windows refused the screen colour effect. The Magnifier or Windows' own colour filters may be using it.",
            },
            ["fr"] = new Dictionary<string, string>
            {
                ["on"] = "Filtre de nuit activé",
                ["off"] = "Filtre de nuit désactivé",
                ["lookGray"] = "Gris et ambre, luminosité {0} %",
                ["lookColour"] = "Ambre, luminosité {0} %",
                ["switch"] = "Filtre de nuit",
                ["gray"] = "Gris avant l’ambre",
                ["brightness"] = "Luminosité",
                ["notify"] = "Notifications",
                ["schedule"] = "Horaire…",
                ["scheduleSet"] = "Horaire : activé à {0}, désactivé à {1}…",
                ["startup"] = "Démarrer avec Windows",
                ["shortcut"] = "Raccourci clavier : {0}",
                ["shortcutTaken"] = "Le raccourci {0} est pris par un autre programme",
                ["quit"] = "Quitter",
                ["schedFollow"] = "Activer et désactiver à heures fixes",
                ["schedOn"] = "Activé à",
                ["schedOff"] = "Désactivé à",
                ["ok"] = "OK",
                ["cancel"] = "Annuler",
                ["welcome"] = "Reader's Night Filter est lancé",
                ["welcomeBody"] = "Son interrupteur est le croissant dans la zone de notification, en bas à droite (sous la flèche ^ si Windows l’a caché). {0} l’active et le désactive aussi.",
                ["failed"] = "Le filtre de nuit n’a pas pu être appliqué",
                ["failedBody"] = "Windows a refusé l’effet de couleur de l’écran. La Loupe ou les filtres de couleur de Windows l’utilisent peut-être.",
            },
            ["de"] = new Dictionary<string, string>
            {
                ["on"] = "Nachtfilter ein",
                ["off"] = "Nachtfilter aus",
                ["lookGray"] = "Grau und Bernstein, Helligkeit {0} %",
                ["lookColour"] = "Bernstein, Helligkeit {0} %",
                ["switch"] = "Nachtfilter",
                ["gray"] = "Grau vor Bernstein",
                ["brightness"] = "Helligkeit",
                ["notify"] = "Benachrichtigungen",
                ["schedule"] = "Zeitplan…",
                ["scheduleSet"] = "Zeitplan: ein um {0}, aus um {1}…",
                ["startup"] = "Mit Windows starten",
                ["shortcut"] = "Tastenkürzel: {0}",
                ["shortcutTaken"] = "Das Tastenkürzel {0} wird von einem anderen Programm verwendet",
                ["quit"] = "Beenden",
                ["schedFollow"] = "Zu festen Zeiten ein- und ausschalten",
                ["schedOn"] = "Ein um",
                ["schedOff"] = "Aus um",
                ["ok"] = "OK",
                ["cancel"] = "Abbrechen",
                ["welcome"] = "Reader's Night Filter läuft",
                ["welcomeBody"] = "Sein Schalter ist die Mondsichel im Infobereich unten rechts (unter dem Pfeil ^, falls Windows sie ausgeblendet hat). Auch {0} schaltet ihn.",
                ["failed"] = "Der Nachtfilter konnte nicht angewendet werden",
                ["failedBody"] = "Windows hat den Farbeffekt des Bildschirms abgelehnt. Vielleicht verwenden ihn die Bildschirmlupe oder die Farbfilter von Windows.",
            },
            ["es"] = new Dictionary<string, string>
            {
                ["on"] = "Filtro nocturno activado",
                ["off"] = "Filtro nocturno desactivado",
                ["lookGray"] = "Gris y ámbar, brillo {0} %",
                ["lookColour"] = "Ámbar, brillo {0} %",
                ["switch"] = "Filtro nocturno",
                ["gray"] = "Gris antes del ámbar",
                ["brightness"] = "Brillo",
                ["notify"] = "Notificaciones",
                ["schedule"] = "Horario…",
                ["scheduleSet"] = "Horario: se activa a las {0}, se desactiva a las {1}…",
                ["startup"] = "Iniciar con Windows",
                ["shortcut"] = "Atajo de teclado: {0}",
                ["shortcutTaken"] = "El atajo {0} lo usa otro programa",
                ["quit"] = "Salir",
                ["schedFollow"] = "Activar y desactivar a horas fijas",
                ["schedOn"] = "Se activa a las",
                ["schedOff"] = "Se desactiva a las",
                ["ok"] = "Aceptar",
                ["cancel"] = "Cancelar",
                ["welcome"] = "Reader's Night Filter está en marcha",
                ["welcomeBody"] = "Su interruptor es la media luna del área de notificación, abajo a la derecha (bajo la flecha ^ si Windows la ha ocultado). {0} también lo activa y desactiva.",
                ["failed"] = "No se ha podido aplicar el filtro nocturno",
                ["failedBody"] = "Windows ha rechazado el efecto de color de la pantalla. Puede que lo estén usando la Lupa o los filtros de color de Windows.",
            },
            ["pt"] = new Dictionary<string, string>
            {
                ["on"] = "Filtro noturno ligado",
                ["off"] = "Filtro noturno desligado",
                ["lookGray"] = "Cinzento e âmbar, brilho {0} %",
                ["lookColour"] = "Âmbar, brilho {0} %",
                ["switch"] = "Filtro noturno",
                ["gray"] = "Cinzento antes do âmbar",
                ["brightness"] = "Brilho",
                ["notify"] = "Notificações",
                ["schedule"] = "Horário…",
                ["scheduleSet"] = "Horário: liga às {0}, desliga às {1}…",
                ["startup"] = "Iniciar com o Windows",
                ["shortcut"] = "Atalho de teclado: {0}",
                ["shortcutTaken"] = "O atalho {0} é usado por outro programa",
                ["quit"] = "Sair",
                ["schedFollow"] = "Ligar e desligar a horas fixas",
                ["schedOn"] = "Liga às",
                ["schedOff"] = "Desliga às",
                ["ok"] = "OK",
                ["cancel"] = "Cancelar",
                ["welcome"] = "O Reader's Night Filter está em execução",
                ["welcomeBody"] = "O seu interruptor é o crescente na área de notificação, em baixo à direita (sob a seta ^ se o Windows o escondeu). {0} também o liga e desliga.",
                ["failed"] = "Não foi possível aplicar o filtro noturno",
                ["failedBody"] = "O Windows recusou o efeito de cor do ecrã. A Lupa ou os filtros de cor do Windows podem estar a usá-lo.",
            },
            ["ru"] = new Dictionary<string, string>
            {
                ["on"] = "Ночной фильтр включён",
                ["off"] = "Ночной фильтр выключен",
                ["lookGray"] = "Серый и янтарный, яркость {0} %",
                ["lookColour"] = "Янтарный, яркость {0} %",
                ["switch"] = "Ночной фильтр",
                ["gray"] = "Серый перед янтарным",
                ["brightness"] = "Яркость",
                ["notify"] = "Уведомления",
                ["schedule"] = "Расписание…",
                ["scheduleSet"] = "Расписание: включается в {0}, выключается в {1}…",
                ["startup"] = "Запускать вместе с Windows",
                ["shortcut"] = "Сочетание клавиш: {0}",
                ["shortcutTaken"] = "Сочетание {0} занято другой программой",
                ["quit"] = "Выйти",
                ["schedFollow"] = "Включать и выключать в заданное время",
                ["schedOn"] = "Включается в",
                ["schedOff"] = "Выключается в",
                ["ok"] = "ОК",
                ["cancel"] = "Отмена",
                ["welcome"] = "Reader's Night Filter запущен",
                ["welcomeBody"] = "Его переключатель — полумесяц в области уведомлений, внизу справа (под стрелкой ^, если Windows его скрыла). {0} тоже включает и выключает его.",
                ["failed"] = "Не удалось применить ночной фильтр",
                ["failedBody"] = "Windows отклонила цветовой эффект экрана. Возможно, его использует экранная лупа или цветовые фильтры Windows.",
            },
        };

        static Dictionary<string, string> table;

        static Dictionary<string, string> Table
        {
            get
            {
                if (table == null)
                {
                    string lang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
                    table = All.TryGetValue(lang, out var t) ? t : All["en"];
                }
                return table;
            }
        }

        public static string Tr(string key, params object[] args)
        {
            string text = Table.TryGetValue(key, out var t) ? t : All["en"].TryGetValue(key, out var e) ? e : key;
            return args.Length == 0 ? text : string.Format(text, args);
        }
    }
}
