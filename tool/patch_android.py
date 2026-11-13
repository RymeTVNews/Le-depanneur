"""Ajoute les permissions et le nom de l'app au projet Android généré par `flutter create`."""
import re
import sys

path = "android/app/src/main/AndroidManifest.xml"
xml = open(path, encoding="utf-8").read()

if "ACCESS_FINE_LOCATION" not in xml:
    block = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <queries>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="geo"/></intent>
    </queries>
"""
    xml, n = re.subn(r"(<manifest[^>]*>)", r"\1" + block, xml, count=1)
    if n != 1:
        sys.exit("manifest introuvable")

xml = re.sub(r'android:label="[^"]*"', 'android:label="Le Dépanneur"', xml, count=1)
open(path, "w", encoding="utf-8").write(xml)
print("AndroidManifest.xml patché")
