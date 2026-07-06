$env:Path = "C:\flutter\bin;" + $env:Path
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
cd "D:\Claude Code - programowanie\moje-wesele-flutter"
flutter build apk --release
explorer "build\app\outputs\flutter-apk"