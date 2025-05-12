import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final LiveSession liveSession;

  const BroadcastScreen({
    Key? key,
    required this.sessionId,
    required this.liveSession,
  }) : super(key: key);

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  bool _isLoading = true;
  bool _isLive = false;
  String? _errorMessage;

  // Agora engine instance
  RtcEngine? _engine;
  String? _token;

  // UI state
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request permissions
      await [Permission.camera, Permission.microphone].request();

      // Get Agora token
      final liveSessionService = ref.read(liveSessionServiceProvider);
      _token = await liveSessionService.generateAgoraToken(
        widget.liveSession.channelName,
        0, // Use 0 for the host
      );

      if (_token == null) {
        throw Exception('Failed to generate Agora token');
      }

      // Create RTC engine instance
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: liveSessionService.agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Setup event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('Local user joined: ${connection.localUid}');
            setState(() {
              _isLive = true;
              _isLoading = false;
            });
          },
          onLeaveChannel: (connection, stats) {
            debugPrint('Local user left');
            setState(() {
              _isLive = false;
            });
          },
          onError: (err, msg) {
            debugPrint('Error: $err - $msg');
            setState(() {
              _errorMessage = 'Error: $msg';
              _isLoading = false;
            });
          },
        ),
      );

      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Join channel
      await _engine!.joinChannel(
        token: _token!,
        channelId: widget.liveSession.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      setState(() {
        _errorMessage = 'Failed to initialize live stream: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _disposeAgora() async {
    try {
      if (_isLive) {
        await _endLiveSession();
      }

      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (e) {
      debugPrint('Error disposing Agora: $e');
    }
  }

  Future<void> _endLiveSession() async {
    try {
      final liveSessionService = ref.read(liveSessionServiceProvider);
      await liveSessionService.endLiveSession(widget.sessionId);
      setState(() {
        _isLive = false;
      });
    } catch (e) {
      debugPrint('Error ending live session: $e');
    }
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleCamera() async {
    await _engine?.enableLocalVideo(!_isCameraOff);
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  void _showEndConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Live Session'),
            content: const Text(
              'Are you sure you want to end this live session? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _endLiveSession();
                  if (mounted) {
                    GoRouter.of(context).pop();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('End Session'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLive) {
          _showEndConfirmation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Live: ${widget.liveSession.title}'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_isLive,
          actions: [
            if (_isLive)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _showEndConfirmation,
                tooltip: 'End Live Session',
              ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Go Back',
                          onPressed: () => GoRouter.of(context).pop(),
                          type: ButtonType.secondary,
                        ),
                      ],
                    ),
                  ),
                )
                : Stack(
                  children: [
                    // Video view
                    Center(
                      child:
                          _engine != null
                              ? AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _engine!,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              )
                              : const Text('Failed to create video view'),
                    ),

                    // Live indicator
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isLive ? Colors.red : Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: _isLive ? Colors.white : Colors.black54,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLive ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                color: _isLive ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Controls
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mute button
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            onPressed: _toggleMute,
                          ),
                          const SizedBox(width: 24),

                          // Camera toggle button
                          _buildControlButton(
                            icon:
                                _isCameraOff
                                    ? Icons.videocam_off
                                    : Icons.videocam,
                            label: _isCameraOff ? 'Camera On' : 'Camera Off',
                            onPressed: _toggleCamera,
                          ),
                          const SizedBox(width: 24),

                          // Switch camera button
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            label: 'Switch',
                            onPressed: _switchCamera,
                          ),
                          const SizedBox(width: 24),

                          // End button
                          _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End',
                            backgroundColor: Colors.red,
                            onPressed: _showEndConfirmation,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.black54,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
