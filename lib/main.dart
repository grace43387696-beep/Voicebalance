import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

void main() => runApp(const VoiceGuideApp());

class VoiceGuideApp extends StatelessWidget {
  const VoiceGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '내 목소리 가이드',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const VoiceGuidePage(),
    );
  }
}

class VoiceGuidePage extends StatefulWidget {
  const VoiceGuidePage({super.key});

  @override
  State<VoiceGuidePage> createState() => _VoiceGuidePageState();
}

class _VoiceGuidePageState extends State<VoiceGuidePage> {
  final Record recorder = Record();
  StreamSubscription<Amplitude>? subscription;

  bool running = false;
  bool measuringAmbient = false;
  bool measuringVoice = false;

  double? currentDb;
  double? ambientDb;
  double? voiceDb;

  final List<double> ambientSamples = [];
  final List<double> voiceSamples = [];

  String result = '측정을 시작하세요';
  Color lightColor = Colors.blueGrey;

  Future<void> start() async {
    if (running) return;

    try {
      if (!await recorder.hasPermission()) {
        message('마이크 권한을 허용해 주세요.');
        return;
      }

      await recorder.start(
        // path와 옵션은 필요에 맞게 조정하세요
        path: 'voice_guide_temp.wav',
        encoder: AudioEncoder.wav,
        // samplingRate / numChannels parameter names may vary by package version.
        // Adjust or remove if your version uses different param names.
        samplingRate: 16000,
        numChannels: 1,
      );

      subscription = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((a) {
        if (!mounted) return;

        setState(() {
          currentDb = a.current;

          if (measuringAmbient) {
            ambientSamples.add(a.current);
          } else if (measuringVoice) {
            voiceSamples.add(a.current);
          } else {
            judge(a.current);
          }
        });
      });

      setState(() {
        running = true;
        result = '측정 중';
      });
    } catch (e) {
      message('마이크 시작 오류: $e');
    }
  }

  void judge(double db) {
    if (measuringAmbient || measuringVoice) return;

    if (ambientDb == null || voiceDb == null) {
      result = '먼저 기준을 측정하세요';
      lightColor = Colors.blueGrey;
      return;
    }

    if (db < -50) {
      result = '말해 보세요';
      lightColor = Colors.blueGrey;
      return;
    }

    final ambientDiff = db - ambientDb!;
    final voiceDiff = db - voiceDb!;

    if (ambientDiff >= 8 && ambientDiff <= 20 && voiceDiff.abs() <= 4) {
      result = '적절';
      lightColor = Colors.green;
    } else {
      result = voiceDiff < -4 ? '조금 더 크게' : '조금 더 작게';
      lightColor = Colors.red;
    }
  }

  Future<void> calibrate(bool ambient) async {
    if (!running) {
      message('먼저 측정을 시작하세요.');
      return;
    }

    final samples = ambient ? ambientSamples : voiceSamples;
    samples.clear();

    setState(() {
      measuringAmbient = ambient;
      measuringVoice = !ambient;
      result = ambient ? '주변 소리 측정 중' : '평소 목소리 측정 중';
      lightColor = Colors.blueGrey;
    });

    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    if (samples.length < 5) {
      setState(() {
        measuringAmbient = false;
        measuringVoice = false;
        result = '다시 측정해 주세요';
      });
      return;
    }

    samples.sort();
    final value = samples[samples.length ~/ 2];

    setState(() {
      if (ambient) {
        ambientDb = value;
      } else {
        voiceDb = value;
      }
      measuringAmbient = false;
      measuringVoice = false;
      result = '기준 저장 완료';
    });
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> stop() async {
    try {
      await recorder.stop();
    } catch (_) {
      // stop 실패해도 계속 진행
    }

    await subscription?.cancel();
    subscription = null;

    if (!mounted) return;

    setState(() {
      running = false;
      measuringAmbient = false;
      measuringVoice = false;
      currentDb = null;
      result = '측정 중지';
      lightColor = Colors.blueGrey;
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 간단한 UI: 상태 표시와 버튼들
    return Scaffold(
      appBar: AppBar(title: const Text('내 목소리 가이드')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(result, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Icon(Icons.circle, color: lightColor, size: 48),
            const SizedBox(height: 12),
            Text('현재 dB: ${currentDb?.toStringAsFixed(1) ?? "-"}'),
            const SizedBox(height: 24),
            Wrap(spacing: 8, children: [
              ElevatedButton(
                  onPressed: running ? null : start, child: const Text('시작')),
              ElevatedButton(
                  onPressed: running ? stop : null, child: const Text('중지')),
              ElevatedButton(
                  onPressed: running ? () => calibrate(true) : null, child: const Text('주변 기준 측정')),
              ElevatedButton(
                  onPressed: running ? () => calibrate(false) : null, child: const Text('목소리 기준 측정')),
            ]),
            const SizedBox(height: 24),
            if (ambientDb != null) Text('저장된 주변 dB: ${ambientDb!.toStringAsFixed(1)}'),
            if (voiceDb != null) Text('저장된 목소리 dB: ${voiceDb!.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}
