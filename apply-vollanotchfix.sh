#!/bin/bash
set -e

if [ $UID -eq 0 ]; then
	echo ">> ERROR: Please run this script as the regular user 'phablet'!"
	exit 1
fi

if [ ! -e unity8-notch-hax.patch ]; then
	echo ">> Creating temporary file containing the notch patches..."
	cat << EOF > unity8-notch-hax.patch
diff --git a/Panel.qml b/Panel.qml
index 399d917..0ec6d4a 100644
--- a/Panel.qml
+++ b/Panel.qml
@@ -333,7 +333,7 @@ Item {
             id: panelTitleHolder
             anchors {
                 left: parent.left
-                leftMargin: units.gu(1)
+                leftMargin: units.gu(2.8)
                 right: __indicators.left
                 rightMargin: units.gu(1)
             }
diff --git a/PanelMenu.qml b/PanelMenu.qml
index 1a7ff51..ba70e68 100644
--- a/PanelMenu.qml
+++ b/PanelMenu.qml
@@ -178,6 +178,7 @@ Showable {
         anchors {
             left: parent.left
             right: parent.right
+            rightMargin: expanded ? 0 : units.gu(1.8)
         }
         expanded: false
         enableLateralChanges: false
diff --git a/Shell.qml b/Shell.qml
index 92406c1..3ea41a0 100644
--- a/Shell.qml
+++ b/Shell.qml
@@ -519,7 +519,7 @@ StyledItem {
             anchors.fill: parent //because this draws indicator menus
 
             mode: shell.usageScenario == "desktop" ? "windowed" : "staged"
-            minimizedPanelHeight: units.gu(3)
+            minimizedPanelHeight: units.gu(3.9)
             expandedPanelHeight: units.gu(7)
             applicationMenuContentX: launcher.lockedVisible ? launcher.panelWidth : 0
 
EOF
fi

if ! hash patch 2>/dev/null; then
	echo ">> System utility 'patch' not found, starting installation..."
	mount | grep -q ' / .*ro' && sudo mount -o remount,rw /
	sudo apt install -y patch
fi

echo ">> Copying system files to patch & checking compatability..."
cp /usr/share/unity8/{Shell,Panel/Panel,Panel/PanelMenu}.qml .
if ! patch -p1 < unity8-notch-hax.patch; then
	echo ">> ERROR: System files are incompatible with the notch patch;"
	echo "          Please adjust this script manually and try again!"
	rm unity8-notch-hax.patch
	exit 1
fi

echo ">> Patches applied successfully! Proceeding to replacing system files..."
mount | grep -q ' / .*ro' && sudo mount -o remount,rw /
sudo mv Shell.qml /usr/share/unity8/
sudo mv Panel.qml /usr/share/unity8/Panel/
sudo mv PanelMenu.qml /usr/share/unity8/Panel/
sudo mount -o remount,ro /

read -p ">> All done, would you like to restart unity8 right now (Y/n)? " ans
[[ -z "$ans" || "${ans^^}" = "Y"* ]] && \
	initctl restart unity8 || \
	echo ">> Please reboot later for the changes to take effect!"
rm unity8-notch-hax.patch
