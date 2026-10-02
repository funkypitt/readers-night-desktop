#!/usr/bin/env bash
# Reader's Night Filter for the desktop: installer.
#
#   bash readers-night-install.sh              install or update, for this user only
#   bash readers-night-install.sh --uninstall  remove everything it installed
#
# Nothing is written outside the home folder and nothing needs root. The files are
# carried at the end of this script.

set -eu

VERSION="@VERSION@"
UUID="readers-night@gallaz.ch"
EFFECT="readersnight"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
EXT_DIR="$DATA/gnome-shell/extensions/$UUID"
EFFECT_DIR="$DATA/kwin/effects/$EFFECT"
ICON="$DATA/icons/hicolor/scalable/apps/readers-night.svg"
LAUNCHER="$DATA/applications/readers-night.desktop"

lang="${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}"
lang="${lang:0:2}"
case "$lang" in fr|de|es|pt|ru) ;; *) lang=en ;; esac

say() {
    local text
    case "$lang:$1" in
        en:no_desktop) text="Reader's Night Filter works on GNOME and on KDE Plasma. Run this installer from inside one of those sessions." ;;
        en:old_gnome) text="This is GNOME %s. The filter needs GNOME 45 or newer." ;;
        en:old_plasma) text="The filter needs KDE Plasma 6." ;;
        en:done_gnome) text="Installed. Log out and log back in: the filter then comes on, and its switch is in the quick settings (top right of the screen), named Night Filter." ;;
        en:done_gnome_x11) text="In an Xorg session, Alt+F2, then r, then Enter does the same without logging out." ;;
        en:done_plasma) text="Installed, and the filter is on. Its switch is Reader's Night Filter in the application menu; pin it to the panel to have it one click away." ;;
        en:failed_plasma) text="Installed, but KWin refused to load the effect. Try again after logging out and back in." ;;
        en:command) text="From a terminal: %s on | off | toggle | schedule 21:30 07:00" ;;
        en:removed) text="Reader's Night Filter is removed." ;;
        en:removed_gnome) text="The extension leaves the running session at the next logout." ;;
        en:broken) text="This copy of the installer is damaged (its files could not be read). Copy it again." ;;

        fr:no_desktop) text="Reader's Night Filter fonctionne sous GNOME et sous KDE Plasma. Lancez cet installateur depuis l’une de ces sessions." ;;
        fr:old_gnome) text="Ceci est GNOME %s. Le filtre demande GNOME 45 ou plus récent." ;;
        fr:old_plasma) text="Le filtre demande KDE Plasma 6." ;;
        fr:done_gnome) text="Installé. Fermez la session puis rouvrez-la : le filtre s’active alors, et son interrupteur se trouve dans les réglages rapides (en haut à droite de l’écran), sous le nom Filtre de nuit." ;;
        fr:done_gnome_x11) text="Dans une session Xorg, Alt+F2, puis r, puis Entrée fait la même chose sans fermer la session." ;;
        fr:done_plasma) text="Installé, et le filtre est actif. Son interrupteur est Reader's Night Filter dans le menu des applications ; épinglez-le au tableau de bord pour l’avoir à un clic." ;;
        fr:failed_plasma) text="Installé, mais KWin a refusé de charger l’effet. Réessayez après avoir fermé puis rouvert la session." ;;
        fr:command) text="Depuis un terminal : %s on | off | toggle | schedule 21:30 07:00" ;;
        fr:removed) text="Reader's Night Filter est supprimé." ;;
        fr:removed_gnome) text="L’extension quitte la session en cours à la prochaine fermeture de session." ;;
        fr:broken) text="Cette copie de l’installateur est abîmée (ses fichiers sont illisibles). Copiez-la de nouveau." ;;

        de:no_desktop) text="Reader's Night Filter läuft unter GNOME und KDE Plasma. Starten Sie dieses Installationsprogramm in einer dieser Sitzungen." ;;
        de:old_gnome) text="Dies ist GNOME %s. Der Filter braucht GNOME 45 oder neuer." ;;
        de:old_plasma) text="Der Filter braucht KDE Plasma 6." ;;
        de:done_gnome) text="Installiert. Melden Sie sich ab und wieder an: Der Filter schaltet sich dann ein, und sein Schalter liegt in den Schnelleinstellungen (oben rechts am Bildschirm) unter dem Namen Nachtfilter." ;;
        de:done_gnome_x11) text="In einer Xorg-Sitzung bewirkt Alt+F2, dann r, dann Eingabe dasselbe ohne Abmelden." ;;
        de:done_plasma) text="Installiert, und der Filter ist eingeschaltet. Sein Schalter ist Reader's Night Filter im Anwendungsmenü; heften Sie ihn an die Kontrollleiste, um ihn mit einem Klick zu erreichen." ;;
        de:failed_plasma) text="Installiert, aber KWin hat den Effekt nicht geladen. Versuchen Sie es nach dem Ab- und Anmelden erneut." ;;
        de:command) text="Im Terminal: %s on | off | toggle | schedule 21:30 07:00" ;;
        de:removed) text="Reader's Night Filter wurde entfernt." ;;
        de:removed_gnome) text="Die Erweiterung verlässt die laufende Sitzung bei der nächsten Abmeldung." ;;
        de:broken) text="Diese Kopie des Installationsprogramms ist beschädigt (ihre Dateien sind nicht lesbar). Kopieren Sie sie erneut." ;;

        es:no_desktop) text="Reader's Night Filter funciona en GNOME y en KDE Plasma. Ejecute este instalador desde una de esas sesiones." ;;
        es:old_gnome) text="Esto es GNOME %s. El filtro necesita GNOME 45 o posterior." ;;
        es:old_plasma) text="El filtro necesita KDE Plasma 6." ;;
        es:done_gnome) text="Instalado. Cierre la sesión y vuelva a abrirla: el filtro se activa entonces, y su interruptor está en los ajustes rápidos (arriba a la derecha de la pantalla), con el nombre Filtro nocturno." ;;
        es:done_gnome_x11) text="En una sesión Xorg, Alt+F2, luego r, luego Intro hace lo mismo sin cerrar la sesión." ;;
        es:done_plasma) text="Instalado, y el filtro está activado. Su interruptor es Reader's Night Filter en el menú de aplicaciones; ánclelo al panel para tenerlo a un clic." ;;
        es:failed_plasma) text="Instalado, pero KWin se ha negado a cargar el efecto. Inténtelo de nuevo tras cerrar y abrir la sesión." ;;
        es:command) text="Desde un terminal: %s on | off | toggle | schedule 21:30 07:00" ;;
        es:removed) text="Reader's Night Filter se ha eliminado." ;;
        es:removed_gnome) text="La extensión abandona la sesión en curso al cerrar la sesión." ;;
        es:broken) text="Esta copia del instalador está dañada (sus archivos no se pueden leer). Cópiela de nuevo." ;;

        pt:no_desktop) text="O Reader's Night Filter funciona no GNOME e no KDE Plasma. Execute este instalador a partir de uma dessas sessões." ;;
        pt:old_gnome) text="Este é o GNOME %s. O filtro precisa do GNOME 45 ou mais recente." ;;
        pt:old_plasma) text="O filtro precisa do KDE Plasma 6." ;;
        pt:done_gnome) text="Instalado. Termine a sessão e volte a iniciá-la: o filtro liga-se então, e o seu interruptor está nas definições rápidas (canto superior direito do ecrã), com o nome Filtro noturno." ;;
        pt:done_gnome_x11) text="Numa sessão Xorg, Alt+F2, depois r, depois Enter faz o mesmo sem terminar a sessão." ;;
        pt:done_plasma) text="Instalado, e o filtro está ligado. O seu interruptor é Reader's Night Filter no menu de aplicações; fixe-o no painel para o ter a um clique." ;;
        pt:failed_plasma) text="Instalado, mas o KWin recusou carregar o efeito. Tente de novo depois de terminar e reiniciar a sessão." ;;
        pt:command) text="A partir de um terminal: %s on | off | toggle | schedule 21:30 07:00" ;;
        pt:removed) text="O Reader's Night Filter foi removido." ;;
        pt:removed_gnome) text="A extensão sai da sessão em curso no próximo fim de sessão." ;;
        pt:broken) text="Esta cópia do instalador está danificada (os seus ficheiros não podem ser lidos). Copie-a de novo." ;;

        ru:no_desktop) text="Reader's Night Filter работает в GNOME и в KDE Plasma. Запустите этот установщик из одного из этих сеансов." ;;
        ru:old_gnome) text="Это GNOME %s. Фильтру нужен GNOME 45 или новее." ;;
        ru:old_plasma) text="Фильтру нужна KDE Plasma 6." ;;
        ru:done_gnome) text="Установлено. Выйдите из сеанса и войдите снова: фильтр включится, а его переключатель находится в быстрых настройках (правый верхний угол экрана) под названием «Ночной фильтр»." ;;
        ru:done_gnome_x11) text="В сеансе Xorg то же самое делает Alt+F2, затем r, затем Enter, без выхода из сеанса." ;;
        ru:done_plasma) text="Установлено, фильтр включён. Его переключатель — Reader's Night Filter в меню приложений; закрепите его на панели, чтобы он был в одном щелчке." ;;
        ru:failed_plasma) text="Установлено, но KWin отказался загрузить эффект. Повторите после выхода из сеанса и нового входа." ;;
        ru:command) text="Из терминала: %s on | off | toggle | schedule 21:30 07:00" ;;
        ru:removed) text="Reader's Night Filter удалён." ;;
        ru:removed_gnome) text="Расширение покинет текущий сеанс при следующем выходе из него." ;;
        ru:broken) text="Эта копия установщика повреждена (её файлы не читаются). Скопируйте её заново." ;;
    esac
    # shellcheck disable=SC2059
    printf "$text\n" "${@:2}"
}

case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*) DESKTOP=gnome ;;
    *KDE*) DESKTOP=plasma ;;
    *) say no_desktop >&2; exit 4 ;;
esac

# --- GNOME's list of enabled extensions, edited as text ------------------------

enabled_list() { gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []"; }

enable_extension() {
    local list; list="$(enabled_list)"
    case "$list" in
        *"'$UUID'"*) ;;
        "@as []"|"[]") gsettings set org.gnome.shell enabled-extensions "['$UUID']" ;;
        *) gsettings set org.gnome.shell enabled-extensions "${list%]}, '$UUID']" ;;
    esac
    # A user who once switched it off by hand has it in the opposite list too.
    local off; off="$(gsettings get org.gnome.shell disabled-extensions 2>/dev/null || echo "@as []")"
    case "$off" in *"'$UUID'"*)
        off="${off//"'$UUID', "/}"; off="${off//", '$UUID'"/}"; off="${off//"'$UUID'"/}"
        [ "$off" = "[]" ] && off="@as []"
        gsettings set org.gnome.shell disabled-extensions "$off" ;;
    esac
}

disable_extension() {
    local list; list="$(enabled_list)"
    case "$list" in *"'$UUID'"*)
        list="${list//"'$UUID', "/}"; list="${list//", '$UUID'"/}"; list="${list//"'$UUID'"/}"
        [ "$list" = "[]" ] && list="@as []"
        gsettings set org.gnome.shell enabled-extensions "$list" ;;
    esac
}

# --- uninstall -----------------------------------------------------------------

uninstall() {
    if [ -x "$BIN/readers-night" ]; then
        "$BIN/readers-night" notify off >/dev/null 2>&1 || true
        "$BIN/readers-night" schedule off >/dev/null 2>&1 || true
        "$BIN/readers-night" off >/dev/null 2>&1 || true
    fi
    if [ "$DESKTOP" = gnome ]; then
        disable_extension
        command -v dconf >/dev/null 2>&1 && dconf reset -f /org/gnome/shell/extensions/readers-night/ || true
    else
        kwriteconfig6 --file kwinrc --group Plugins --key "${EFFECT}Enabled" --delete 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Effect-$EFFECT" --key Brightness --delete 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Effect-$EFFECT" --key Grayscale --delete 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Effect-$EFFECT" --key Notify --delete 2>/dev/null || true
    fi
    rm -rf "$EXT_DIR" "$EFFECT_DIR" "$CONF/readers-night"
    rm -f "$BIN/readers-night" "$ICON" "$LAUNCHER"
    say removed
    [ "$DESKTOP" = gnome ] && say removed_gnome
    exit 0
}

[ "${1:-}" = "--uninstall" ] && uninstall

# --- checks --------------------------------------------------------------------

if [ "$DESKTOP" = gnome ]; then
    shell_version="$(gnome-shell --version 2>/dev/null | grep -o '[0-9]\+' | head -1 || true)"
    if [ -z "$shell_version" ] || [ "$shell_version" -lt 45 ]; then
        say old_gnome "${shell_version:-?}" >&2; exit 6
    fi
else
    command -v kwriteconfig6 >/dev/null 2>&1 || { say old_plasma >&2; exit 6; }
fi

# --- unpack --------------------------------------------------------------------

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
if ! sed '1,/^__FILES__$/d' "$0" | base64 -d 2>/dev/null | tar -xz -C "$work" 2>/dev/null \
        || [ ! -x "$work/bin/readers-night" ]; then
    say broken >&2; exit 7
fi

# --- install -------------------------------------------------------------------

mkdir -p "$BIN" "$CONF/readers-night" "$(dirname "$ICON")"
install -m 755 "$work/bin/readers-night" "$BIN/readers-night"
install -m 644 "$work/icons/readers-night.svg" "$ICON"
echo "$DESKTOP" > "$CONF/readers-night/backend"
echo "$VERSION" > "$CONF/readers-night/version"

if [ "$DESKTOP" = gnome ]; then
    rm -rf "$EXT_DIR"
    mkdir -p "$(dirname "$EXT_DIR")"
    cp -r "$work/gnome/$UUID" "$EXT_DIR"
    # The compiled settings description comes ready; recompiled here when the tool is at hand.
    command -v glib-compile-schemas >/dev/null 2>&1 && glib-compile-schemas "$EXT_DIR/schemas" 2>/dev/null || true
    enable_extension
    "$BIN/readers-night" on >/dev/null 2>&1 || true
    say done_gnome
    [ "${XDG_SESSION_TYPE:-}" = x11 ] && say done_gnome_x11
else
    rm -rf "$EFFECT_DIR"
    mkdir -p "$(dirname "$EFFECT_DIR")" "$(dirname "$LAUNCHER")"
    cp -r "$work/plasma/$EFFECT" "$EFFECT_DIR"
    {
        echo "[Desktop Entry]"
        echo "Type=Application"
        echo "Name=Reader's Night Filter"
        echo "Comment=Switch the night filter on or off"
        echo "Comment[fr]=Activer ou désactiver le filtre de nuit"
        echo "Comment[de]=Nachtfilter ein- oder ausschalten"
        echo "Comment[es]=Activar o desactivar el filtro nocturno"
        echo "Comment[pt]=Ligar ou desligar o filtro noturno"
        echo "Comment[ru]=Включить или выключить ночной фильтр"
        echo "Exec=$BIN/readers-night toggle"
        echo "Icon=$ICON"
        echo "Terminal=false"
        echo "Categories=Utility;"
        echo "StartupNotify=false"
    } > "$LAUNCHER"
    # An update: the effect already loaded is the old one.
    "$BIN/readers-night" off >/dev/null 2>&1 || true
    if "$BIN/readers-night" on >/dev/null 2>&1; then say done_plasma; else say failed_plasma; fi
fi

case ":$PATH:" in
    *":$BIN:"*) say command "readers-night" ;;
    *) say command "$BIN/readers-night" ;;
esac
exit 0

__FILES__
