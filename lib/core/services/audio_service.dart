import 'dart:io';

class AudioService {
  /// Plays a loud siren-like alarm sound followed by a spoken "END" word.
  /// Writes a temporary PowerShell script to ensure perfect variable escaping and execution.
  static Future<void> playAlertSound() async {
    try {
      if (Platform.isWindows) {
        final tempDir = Directory.systemTemp;
        final scriptFile = File('${tempDir.path}\\sparta_gym_alert.ps1');

        // Write the sound and Text-to-Speech instructions
        await scriptFile.writeAsString('''
[Console]::Beep(1000, 200)
[Console]::Beep(1500, 200)
[Console]::Beep(1000, 200)
[Console]::Beep(1500, 200)
[Console]::Beep(1000, 200)
[Console]::Beep(1500, 200)
[Console]::Beep(1000, 200)
[Console]::Beep(1500, 200)

Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$synth.Volume = 100
\$synth.Speak("The subscription is ended")
\$synth.Dispose()
''', flush: true);

        // Execute the script asynchronously
        Process.run('powershell.exe', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          scriptFile.path,
        ]);
      }
    } catch (e) {
      // Silently ignore if sound cannot be played
    }
  }
}
