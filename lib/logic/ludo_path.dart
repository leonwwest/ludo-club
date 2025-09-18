Current runner version: '2.328.0'
Runner Image Provisioner
Operating System
Runner Image
GITHUB_TOKEN Permissions
Secret source: Actions
Prepare workflow directory
Prepare all required actions
Getting action download info
Download action repository 'actions/checkout@v4' (SHA:08eba0b27e820071cde6df949e0beb9ba4906955)
Download action repository 'subosito/flutter-action@v2' (SHA:fd55f4c5af5b953cc57a2be44cb082c8f6635e8e)
Download action repository 'actions/cache@v4' (SHA:0400d5f644dc74513175e3cd8d07132dd4860809)
Download action repository 'actions/upload-artifact@v4' (SHA:ea165f8d65b6e75b540449e92b4886f43607fa02)
Getting action download info
Complete job name: build
0s
Run actions/checkout@v4
Syncing repository: leonwwest/ludo_club
Getting Git version info
Temporarily overriding HOME='/home/runner/work/_temp/87973d8d-5ce6-4040-81fd-a379f3da0b1e' before making global git config changes
Adding repository directory to the temporary git global config as a safe directory
/usr/bin/git config --global --add safe.directory /home/runner/work/ludo_club/ludo_club
Deleting the contents of '/home/runner/work/ludo_club/ludo_club'
Initializing the repository
Disabling automatic garbage collection
Setting up auth
Fetching the repository
Determining the checkout info
/usr/bin/git sparse-checkout disable
/usr/bin/git config --local --unset-all extensions.worktreeConfig
Checking out the ref
/usr/bin/git log -1 --format=%H
8b39decab9288f94397479103cb55e772753bbb7
35s
Run subosito/flutter-action@v2
Run chmod +x "$GITHUB_ACTION_PATH/setup.sh"
Run $GITHUB_ACTION_PATH/setup.sh -p \
Run actions/cache@v4
Cache not found for input keys: flutter-linux-stable-3.22.2-x64-761747bfc538b5af34aa0d3fac380f1bc331ec49
Run actions/cache@v4
Cache not found for input keys: flutter-pub-linux-stable-3.22.2-x64-761747bfc538b5af34aa0d3fac380f1bc331ec49-c76cca1b1fb581cd812bf4f51057325e0d8fb812841c29aed74c4ed8b2679cd2
Run $GITHUB_ACTION_PATH/setup.sh \
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0  714M    0 28812    0     0   291k      0  0:41:50 --:--:--  0:41:50  290k
 27  714M   27  193M    0     0   178M      0  0:00:04  0:00:01  0:00:03  178M
 55  714M   55  393M    0     0   187M      0  0:00:03  0:00:02  0:00:01  187M
 82  714M   82  592M    0     0   192M      0  0:00:03  0:00:03 --:--:--  192M
100  714M  100  714M    0     0   192M      0  0:00:03  0:00:03 --:--:--  192M
1s
Run flutter config --enable-web

  ╔════════════════════════════════════════════════════════════════════════════╗
  ║                 Welcome to Flutter! - https://flutter.dev                  ║
  ║                                                                            ║
  ║ The Flutter tool uses Google Analytics to anonymously report feature usage ║
  ║ statistics and basic crash reports. This data is used to help improve      ║
  ║ Flutter tools over time.                                                   ║
  ║                                                                            ║
  ║ Flutter tool analytics are not sent on the very first run. To disable      ║
  ║ reporting, type 'flutter config --no-analytics'. To display the current    ║
  ║ setting, type 'flutter config'. If you opt out of analytics, an opt-out    ║
  ║ event will be sent, and then no further information will be sent by the    ║
  ║ Flutter tool.                                                              ║
  ║                                                                            ║
  ║ By downloading the Flutter SDK, you agree to the Google Terms of Service.  ║
  ║ The Google Privacy Policy describes how data is handled in this service.   ║
  ║                                                                            ║
  ║ Moreover, Flutter includes the Dart SDK, which may send usage metrics and  ║
  ║ crash reports to Google.                                                   ║
  ║                                                                            ║
  ║ Read about data we send with crash reports:                                ║
  ║ https://flutter.dev/docs/reference/crash-reporting                         ║
  ║                                                                            ║
  ║ See Google's privacy policy:                                               ║
  ║ https://policies.google.com/privacy                                        ║
  ║                                                                            ║
  ║ To disable animations in this tool, use                                    ║
  ║ 'flutter config --no-cli-animations'.                                      ║
  ╚════════════════════════════════════════════════════════════════════════════╝

Setting "enable-web" value to "true".

You may need to restart any open editors for them to read new settings.
0s
Run actions/cache@v4
Cache not found for input keys: Linux-pub-c76cca1b1fb581cd812bf4f51057325e0d8fb812841c29aed74c4ed8b2679cd2, Linux-pub-
8s
Run flutter pub get
Resolving dependencies...
The current Dart SDK version is 3.4.3.

Because flutter_lints 5.0.0 requires SDK version ^3.5.0 and no versions of flutter_lints match >5.0.0 <6.0.0, flutter_lints ^5.0.0 is forbidden.
So, because ludo_club depends on flutter_lints ^5.0.0, version solving failed.


You can try one of the following suggestions to make the pubspec resolve:
* Try using the Flutter SDK version: 3.35.4. 
* Consider downgrading your constraint on flutter_lints: flutter pub add dev:flutter_lints:^4.0.0
Error: Process completed with exit code 1.
0s
0s
0s
0s
0s
0s
0s
0s
Post job cleanup.
0s
Post job cleanup.
/usr/bin/git version
git version 2.51.0
Temporarily overriding HOME='/home/runner/work/_temp/08f1b4ba-2d4f-4d27-aeef-05db13d29248' before making global git config changes
Adding repository directory to the temporary git global config as a safe directory
/usr/bin/git config --global --add safe.directory /home/runner/work/ludo_club/ludo_club
/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
http.https://github.com/.extraheader
/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
1s
Cleaning up orphan processesimport 'dart:ui';

/// Canonical 52 main-path grid coordinates (col,row) on a 15x15 board.
/// Indices: 0/13/26/39 are start tiles; 12/25/38/51 are home-entry tiles.
class LudoPath {
  static const List<Offset> coords = [
    // Bottom vertical up (left of red goal lane)
    Offset(6, 13), // 0  Red start
    Offset(6, 12), // 1
    Offset(6, 11), // 2
    Offset(6, 10), // 3
    Offset(6, 9),  // 4
    Offset(6, 8),  // 5
    // Bottom horizontal left
    Offset(5, 8),  // 6
    Offset(4, 8),  // 7
    Offset(3, 8),  // 8
    Offset(2, 8),  // 9
    Offset(1, 8),  // 10
    Offset(0, 8),  // 11
    // Left middle (green entry)
    Offset(0, 7),  // 12 Green home entry
    // Above green lane (row 6)
    Offset(1, 6),  // 13 Green start
    Offset(2, 6),  // 14
    Offset(3, 6),  // 15
    Offset(4, 6),  // 16
    Offset(5, 6),  // 17
    Offset(6, 6),  // 18
    // Up towards top edge (col 6)
    Offset(6, 5),  // 19
    Offset(6, 4),  // 20
    Offset(6, 3),  // 21
    Offset(6, 2),  // 22
    Offset(6, 1),  // 23
    Offset(6, 0),  // 24 (top edge)
    // Corner across top gap away from blue lane
    Offset(7, 0),  // 25 Blue home entry
    Offset(8, 0),  // 26 Blue start
    // Down alongside blue lane (col 8)
    Offset(8, 1),  // 27
    Offset(8, 2),  // 28
    Offset(8, 3),  // 29
    Offset(8, 4),  // 30
    Offset(8, 5),  // 31
    Offset(8, 6),  // 32
    // Right along row 6
    Offset(9, 6),  // 33
    Offset(10, 6), // 34
    Offset(11, 6), // 35
    Offset(12, 6), // 36
    Offset(13, 6), // 37
    Offset(14, 6), // 38 Yellow home entry
    Offset(14, 7), // 39 Yellow start
    // Right segment below yellow lane (row 8, moving left)
    Offset(14, 8), // 40
    Offset(13, 8), // 41
    Offset(12, 8), // 42
    Offset(11, 8), // 43
    Offset(10, 8), // 44
    Offset(9, 8),  // 45
    Offset(8, 8),  // 46
    // Turn up towards red entry
    Offset(8, 9),  // 47
    Offset(8, 10), // 48
    Offset(8, 11), // 49
    Offset(9, 12), // 50 transition
    Offset(8, 12), // 51 Red home entry
  ];
}
