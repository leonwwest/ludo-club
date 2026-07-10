import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/online_error_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/online_room_client.dart';
import 'package:ludo_club/online/room_protocol.dart';
import 'package:ludo_club/theme/player_palette.dart';

class OnlineRoomSheet extends StatefulWidget {
  const OnlineRoomSheet({
    required this.initialState,
    required this.onAttached,
    required this.onOpenGame,
    required this.onLeave,
    super.key,
  });

  final LudoGameState initialState;
  final ValueChanged<OnlineRoomClient> onAttached;
  final VoidCallback onOpenGame;
  final Future<void> Function() onLeave;

  @override
  State<OnlineRoomSheet> createState() => _OnlineRoomSheetState();
}

class _OnlineRoomSheetState extends State<OnlineRoomSheet> {
  static const _defaultServer = String.fromEnvironment(
    'LUDO_ROOM_SERVER',
    defaultValue: 'ws://127.0.0.1:8080/ws',
  );

  late final TextEditingController _serverController;
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  OnlineRoomClient? _client;
  bool _createMode = true;
  bool _busy = false;
  bool _handedOff = false;
  int _playerCount = 2;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: _defaultServer);
    _nameController = TextEditingController(
      text: widget.initialState.players.first.name,
    );
    _codeController = TextEditingController();
    _playerCount = widget.initialState.players.length.clamp(2, 4);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    final client = _client;
    client?.removeListener(_handleClientChange);
    if (!_handedOff) {
      client?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final client = _client;
    final snapshot = client?.snapshot;
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brass.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                      border: Border.all(color: AppColors.brassHairline),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.public, color: AppColors.brassDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.onlineRoom,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          l10n.onlineRoomSubtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: _close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot == null) ...[
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.add_link),
                      label: Text(l10n.createRoom),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.login),
                      label: Text(l10n.joinRoom),
                    ),
                  ],
                  selected: {_createMode},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) {
                          setState(() => _createMode = selection.first);
                        },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _serverController,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.serverAddress,
                    prefixIcon: const Icon(Icons.dns_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  enabled: !_busy,
                  textInputAction:
                      _createMode ? TextInputAction.done : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.playerName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                if (_createMode)
                  SegmentedButton<int>(
                    segments: [
                      for (final count in [2, 3, 4])
                        ButtonSegment(
                          value: count,
                          label: Text(l10n.playerCountLabel(count)),
                        ),
                    ],
                    selected: {_playerCount},
                    onSelectionChanged: _busy
                        ? null
                        : (selection) {
                            setState(() => _playerCount = selection.first);
                          },
                  )
                else
                  TextField(
                    controller: _codeController,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: RoomProtocol.roomCodeLength,
                    decoration: InputDecoration(
                      labelText: l10n.roomCode,
                      hintText: l10n.roomCodeHint,
                      prefixIcon: const Icon(Icons.key_outlined),
                      counterText: '',
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  l10n.onlineServerHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate500,
                      ),
                ),
                if (_formError case final error?) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: error),
                ],
                if (client?.errorMessage case final error?) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: localizedOnlineError(l10n, error)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _connect,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_createMode ? Icons.add_link : Icons.login),
                  label: Text(
                    _busy
                        ? l10n.onlineConnecting
                        : _createMode
                            ? l10n.createRoom
                            : l10n.joinRoom,
                  ),
                ),
              ] else ...[
                _RoomCodePanel(
                  snapshot: snapshot,
                  onCopy: () => _copyCode(snapshot.roomCode),
                ),
                const SizedBox(height: 14),
                _ConnectionPanel(client: client!),
                if (client.errorMessage case final error?) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: localizedOnlineError(l10n, error)),
                ],
                const SizedBox(height: 16),
                if (snapshot.started)
                  FilledButton.icon(
                    onPressed: client.status == OnlineRoomStatus.ready
                        ? () {
                            _detachSheetListener();
                            widget.onOpenGame();
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: const Icon(Icons.sports_esports_outlined),
                    label: Text(
                      client.status == OnlineRoomStatus.reconnecting
                          ? l10n.onlineReconnecting
                          : l10n.onlineReady,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _close,
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.onlineLeave),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(_serverController.text.trim());
    const supportedSchemes = {'ws', 'wss', 'http', 'https'};
    if (uri == null ||
        !uri.hasScheme ||
        !supportedSchemes.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      setState(() => _formError = l10n.invalidServerAddress);
      return;
    }
    if (!_createMode &&
        RoomProtocol.normalizeRoomCode(_codeController.text).length !=
            RoomProtocol.roomCodeLength) {
      setState(() => _formError = l10n.invalidRoomCode);
      return;
    }
    final client = OnlineRoomClient(serverUri: uri);
    client.addListener(_handleClientChange);
    final oldClient = _client;
    oldClient?.removeListener(_handleClientChange);
    oldClient?.dispose();
    setState(() {
      _client = client;
      _busy = true;
      _formError = null;
    });
    try {
      if (_createMode) {
        await client.createRoom(
          playerName: _nameController.text,
          playerCount: _playerCount,
          rules: widget.initialState.rules,
        );
      } else {
        await client.joinRoom(
          roomCode: _codeController.text,
          playerName: _nameController.text,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedOnlineError(l10n, error))),
        );
      }
    }
  }

  void _handleClientChange() {
    if (!mounted) {
      return;
    }
    final client = _client;
    if (client == null) {
      return;
    }
    if (!_handedOff && client.snapshot != null) {
      _handedOff = true;
      widget.onAttached(client);
    }
    setState(() {
      _busy = client.status == OnlineRoomStatus.connecting ||
          client.status == OnlineRoomStatus.reconnecting;
    });
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.onlineCodeCopied)),
      );
    }
  }

  Future<void> _close() async {
    if (_handedOff) {
      _detachSheetListener();
      await widget.onLeave();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _detachSheetListener() {
    _client?.removeListener(_handleClientChange);
    _client = null;
  }
}

class _RoomCodePanel extends StatelessWidget {
  const _RoomCodePanel({required this.snapshot, required this.onCopy});

  final OnlineRoomSnapshot snapshot;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.headerPanel,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.brassHairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.roomCode,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.paper.withValues(alpha: 0.7),
                        ),
                  ),
                  Semantics(
                    label: l10n.roomCodeValue(snapshot.roomCode),
                    readOnly: true,
                    child: ExcludeSemantics(
                      child: SelectableText(
                        snapshot.roomCode,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: l10n.onlineCopyCode,
              onPressed: onCopy,
              style: IconButton.styleFrom(foregroundColor: AppColors.paper),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.client});

  final OnlineRoomClient client;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = client.snapshot!;
    final color = snapshot.localColor.paint;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Icon(
                client.status == OnlineRoomStatus.ready
                    ? Icons.cloud_done
                    : client.status == OnlineRoomStatus.reconnecting
                        ? Icons.sync
                        : Icons.groups_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  switch (client.status) {
                    OnlineRoomStatus.reconnecting => l10n.onlineReconnecting,
                    OnlineRoomStatus.connecting => l10n.onlineConnecting,
                    OnlineRoomStatus.error =>
                      localizedOnlineError(l10n, client.errorMessage),
                    OnlineRoomStatus.ready => l10n.onlineReady,
                    _ => l10n.onlineWaiting(
                        snapshot.connectedPlayers,
                        snapshot.requiredPlayers,
                      ),
                  },
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (snapshot.isHost)
                Tooltip(
                  message: l10n.onlineHost,
                  child: Semantics(
                    label: l10n.onlineHost,
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class OnlineRoomStatusBar extends StatelessWidget {
  const OnlineRoomStatusBar({
    required this.snapshot,
    required this.status,
    required this.errorMessage,
    required this.onLeave,
    super.key,
  });

  final OnlineRoomSnapshot? snapshot;
  final OnlineRoomStatus? status;
  final String? errorMessage;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = snapshot?.localColor.paint ?? AppColors.brass;
    final statusText = errorMessage != null
        ? localizedOnlineError(l10n, errorMessage)
        : switch (status) {
            OnlineRoomStatus.connecting => l10n.onlineConnecting,
            OnlineRoomStatus.reconnecting => l10n.onlineReconnecting,
            OnlineRoomStatus.waitingForPlayers => snapshot == null
                ? l10n.waitingForRoomPlayers
                : l10n.onlineWaiting(
                    snapshot!.connectedPlayers,
                    snapshot!.requiredPlayers,
                  ),
            OnlineRoomStatus.ready => l10n.onlineReady,
            OnlineRoomStatus.error => localizedOnlineError(l10n, errorMessage),
            _ => l10n.onlineRoom,
          };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.headerPanel.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(Icons.public, color: color),
              const SizedBox(width: 9),
              if (snapshot != null) ...[
                Text(
                  snapshot!.roomCode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.paper.withValues(alpha: 0.76),
                      ),
                ),
              ),
              IconButton(
                tooltip: l10n.onlineLeave,
                onPressed: onLeave,
                color: AppColors.paper,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
