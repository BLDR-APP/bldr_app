import 'dart:io';

const String agpVersion = '8.6.1';
const String kotlinVersion = '2.1.0';
const String gradleDist =
    'https://services.gradle.org/distributions/gradle-8.10.2-all.zip';
const int compileSdk = 35;
const int targetSdk = 35;

void main() async {
  final wrapperProps =
  File('android/gradle/wrapper/gradle-wrapper.properties');
  final settingsGradle = File('android/settings.gradle');
  final topLevelBuildGradle = File('android/build.gradle');
  final appBuildGradle = File('android/app/build.gradle');
  final gradleProps = File('android/gradle.properties');

  List<String> missing = [];
  if (!wrapperProps.existsSync()) {
    missing.add(wrapperProps.path);
  }
  if (!settingsGradle.existsSync()) {
    missing.add(settingsGradle.path);
  }
  if (!appBuildGradle.existsSync()) {
    missing.add(appBuildGradle.path);
  }
  if (missing.isNotEmpty) {
    stderr.writeln('Arquivos faltando: ${missing.join(', ')}');
    exit(1);
  }

  String ts() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  void backup(File f) {
    final b = File('${f.path}.bak_${ts()}');
    b.writeAsStringSync(f.readAsStringSync());
    print('  . backup -> ${b.path}');
  }

  String ensureProp(String content, String key, String line) {
    final rx = RegExp('^\\s*${RegExp.escape(key)}\\s*=.*\$', multiLine: true);
    if (rx.hasMatch(content)) return content;
    if (!content.endsWith('\n')) content += '\n';
    return content + line + '\n';
  }

  // 1) gradle-wrapper.properties
  print('\n[1/6] Atualizando gradle-wrapper.properties');
  {
    backup(wrapperProps);
    var c = wrapperProps.readAsStringSync();
    final rx = RegExp('^distributionUrl=.*\$', multiLine: true);
    if (rx.hasMatch(c)) {
      c = c.replaceAll(rx, 'distributionUrl=$gradleDist');
    } else {
      if (!c.endsWith('\n')) c += '\n';
      c += 'distributionUrl=$gradleDist\n';
    }
    wrapperProps.writeAsStringSync(c);
    print('  OK');
  }

  // 2) settings.gradle
  print('\n[2/6] Ajustando settings.gradle');
  var sc = settingsGradle.readAsStringSync();
  final hasPluginsDsl =
      sc.contains(RegExp('\\bpluginManagement\\b')) ||
          sc.contains(RegExp('\\bplugins\\s*\\{'));

  if (hasPluginsDsl) {
    backup(settingsGradle);

    // Atualiza/insere versões no bloco plugins { ... }
    final rxAgp = RegExp(
        'id\\s*[\'"]com\\.android\\.application[\'"]\\s*version\\s*[\'"][0-9.]+[\'"]');
    final rxKotlin = RegExp(
        'id\\s*[\'"]org\\.jetbrains\\.kotlin\\.android[\'"]\\s*version\\s*[\'"][0-9.]+[\'"]');

    if (rxAgp.hasMatch(sc)) {
      sc = sc.replaceAll(
          rxAgp, 'id "com.android.application" version "$agpVersion"');
    } else {
      sc = sc.replaceFirstMapped(RegExp('plugins\\s*\\{'), (m) {
        return '${m.group(0)}\n        id "com.android.application" version "$agpVersion"';
      });
    }

    if (rxKotlin.hasMatch(sc)) {
      sc = sc.replaceAll(
          rxKotlin, 'id "org.jetbrains.kotlin.android" version "$kotlinVersion"');
    } else {
      sc = sc.replaceFirstMapped(RegExp('plugins\\s*\\{'), (m) {
        return '${m.group(0)}\n        id "org.jetbrains.kotlin.android" version "$kotlinVersion"';
      });
    }

    if (!sc.contains('pluginManagement')) {
      sc =
          'pluginManagement {\n'
              '    repositories { gradlePluginPortal(); google(); mavenCentral() }\n'
              '    plugins {\n'
              '        id "com.android.application" version "$agpVersion"\n'
              '        id "org.jetbrains.kotlin.android" version "$kotlinVersion"\n'
              '    }\n'
              '}\n\n' +
              sc;
    }

    if (!sc.contains('dependencyResolutionManagement')) {
      sc += '\n'
          'dependencyResolutionManagement {\n'
          '    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)\n'
          '    repositories { google(); mavenCentral() }\n'
          '}\n';
    }

    settingsGradle.writeAsStringSync(sc);
    print('  OK (template novo)');
  } else {
    print('  Sem plugins DSL (template antigo) – ajustarei android/build.gradle no próximo passo.');
  }

  // 3) android/build.gradle (template antigo)
  if (topLevelBuildGradle.existsSync()) {
    print('\n[3/6] Ajustando android/build.gradle (template antigo)');
    var c = topLevelBuildGradle.readAsStringSync();
    final hasBuildscript = c.contains(RegExp('\\bbuildscript\\b'));
    if (hasBuildscript && !hasPluginsDsl) {
      backup(topLevelBuildGradle);

      final rxAgp = RegExp(
          'classpath\\s*[\'"]com\\.android\\.tools\\.build:gradle:[0-9.]+[\'"]');
      if (rxAgp.hasMatch(c)) {
        c = c.replaceAll(
            rxAgp, "classpath 'com.android.tools.build:gradle:$agpVersion'");
      } else {
        c = c.replaceFirstMapped(
            RegExp('buildscript\\s*\\{[\\s\\S]*?dependencies\\s*\\{'), (m) {
          return '${m.group(0)}\n        classpath "com.android.tools.build:gradle:$agpVersion"';
        });
      }

      final rxKgp = RegExp(
          'classpath\\s*[\'"]org\\.jetbrains\\.kotlin:kotlin-gradle-plugin:[0-9.]+[\'"]');
      if (rxKgp.hasMatch(c)) {
        c = c.replaceAll(rxKgp,
            'classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion"');
      } else {
        c = c.replaceFirstMapped(
            RegExp('buildscript\\s*\\{[\\s\\S]*?dependencies\\s*\\{'), (m) {
          return '${m.group(0)}\n        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion"';
        });
      }

      topLevelBuildGradle.writeAsStringSync(c);
      print('  OK (template antigo)');
    } else {
      print('  Nada a fazer aqui.');
    }
  }

  // 4) android/app/build.gradle
  print('\n[4/6] Ajustando android/app/build.gradle');
  {
    backup(appBuildGradle);
    var c = appBuildGradle.readAsStringSync();

    // Garante plugins
    if (!RegExp('id\\s+["\']com\\.android\\.application["\']').hasMatch(c)) {
      c = c.replaceFirst('plugins {',
          'plugins {\n    id "com.android.application"');
    }
    if (!RegExp('id\\s+["\']org\\.jetbrains\\.kotlin\\.android["\']')
        .hasMatch(c)) {
      c = c.replaceFirst('plugins {',
          'plugins {\n    id "org.jetbrains.kotlin.android"');
    }

    // SDKs
    c = c.replaceAll(RegExp('compileSdk\\s+\\d+'), 'compileSdk $compileSdk');
    c = c.replaceAll(RegExp('targetSdk\\s+\\d+'), 'targetSdk $targetSdk');
    c = c.replaceAll(
        RegExp('targetSdkVersion\\s+\\d+'), 'targetSdk $targetSdk');

    // Java 17
    if (RegExp('compileOptions\\s*\\{').hasMatch(c)) {
      c = c.replaceAll(
          RegExp('sourceCompatibility\\s+JavaVersion\\.VERSION_\\d+'),
          'sourceCompatibility JavaVersion.VERSION_17');
      c = c.replaceAll(
          RegExp('targetCompatibility\\s+JavaVersion\\.VERSION_\\d+'),
          'targetCompatibility JavaVersion.VERSION_17');
    } else {
      c = c.replaceFirst(
          RegExp('android\\s*\\{'),
          'android {\n    compileOptions {\n        sourceCompatibility JavaVersion.VERSION_17\n'
              '        targetCompatibility JavaVersion.VERSION_17\n    }');
    }

    // Kotlin 17
    if (RegExp('kotlinOptions\\s*\\{').hasMatch(c)) {
      c = c.replaceAll(RegExp('jvmTarget\\s*=\\s*["\'][0-9.]+["\']'),
          'jvmTarget = "17"');
    } else {
      c = c.replaceFirst(RegExp('android\\s*\\{'),
          'android {\n    kotlinOptions {\n        jvmTarget = "17"\n    }');
    }

    // kotlin-stdlib (se houver)
    c = c.replaceAll(
        RegExp(
            'implementation\\s+["\']org\\.jetbrains\\.kotlin:kotlin-stdlib:[0-9.]+["\']'),
        'implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion"');

    // buildFeatures { buildConfig true }
    if (!RegExp('buildFeatures\\s*\\{').hasMatch(c)) {
      c = c.replaceFirst(RegExp('android\\s*\\{'),
          'android {\n    buildFeatures { buildConfig true }');
    }

    appBuildGradle.writeAsStringSync(c);
    print('  OK');
  }

  // 5) gradle.properties
  print('\n[5/6] Ajustando android/gradle.properties');
  {
    if (!gradleProps.existsSync()) {
      gradleProps.createSync(recursive: true);
      gradleProps.writeAsStringSync('');
    }
    backup(gradleProps);
    var c = gradleProps.readAsStringSync();

    c = ensureProp(c, 'android.useAndroidX', 'android.useAndroidX=true');
    c = ensureProp(c, 'android.enableJetifier', 'android.enableJetifier=true');

    final jvmRx = RegExp('^org\\.gradle\\.jvmargs=.*\$', multiLine: true);
    if (jvmRx.hasMatch(c)) {
      c = c.replaceAllMapped(jvmRx, (m) {
        var v = m.group(0)!;
        if (!v.contains('-Xmx')) v += ' -Xmx4g';
        if (!v.contains('file.encoding')) v += ' -Dfile.encoding=UTF-8';
        return v;
      });
    } else {
      if (!c.endsWith('\n')) c += '\n';
      c += 'org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8\n';
    }

    c = ensureProp(c, 'kotlin.code.style', 'kotlin.code.style=official');
    c = ensureProp(c, 'kotlin.incremental', 'kotlin.incremental=true');

    gradleProps.writeAsStringSync(c);
    print('  OK');
  }

  // 6) Dicas finais
  print('\n[6/6] Verificações finais');
  print('  * JDK do Android Studio/Gradle = 17.');
  print('  * Se usa Firebase/Google Services, atualize plugins (gms ~ 4.4.2, crashlytics ~ 3.0.2).');

  print('\nConcluído ✅');
  print(
      'Agora rode: flutter clean && rm -rf android/.gradle && flutter pub get && flutter run -v');
}
