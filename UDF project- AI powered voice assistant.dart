import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(const VoiceAssistantApp());

class VoiceAssistant {
  String respond(String command) {
    final text = command.toLowerCase();
    if (text.contains('time')) return 'It is 10:30 AM.';
    if (text.contains('weather')) return 'Sunny, 28 C.';
    if (text.contains('alarm')) return 'Alarm set for 7:00 AM.';
    if (text.contains('play')) return 'Playing your music.';
    return 'Sorry, I did not understand.';
  }
}

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nova',
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final assistant = VoiceAssistant();
  final speech = SpeechToText();
  final List<Message> messages = [];
  bool listening = false;
  String heard = '';

  Future<void> toggleMic() async {
    if (listening) {
      await speech.stop();
      setState(() => listening = false);
      return;
    }
    final ok = await speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => listening = false);
        }
      },
      onError: (e) {
        if (mounted) setState(() => listening = false);
      },
    );
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission needed')),
      );
      return;
    }
    setState(() {
      listening = true;
      heard = '';
    });
    speech.listen(onResult: (r) {
      setState(() => heard = r.recognizedWords);
      if (r.finalResult && r.recognizedWords.isNotEmpty) {
        final words = r.recognizedWords;
        final reply = assistant.respond(words);
        setState(() {
          messages.add(Message(words, true));
          messages.add(Message(reply, false));
          heard = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                return Align(
                  alignment: m.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Card(
                    color: m.isUser
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(m.text),
                    ),
                  ),
                );
              },
            ),
          ),
          if (listening)
            Padding(
              padding: const EdgeInsets.only(bottom: 110),
              child: Text('Listening... $heard'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: toggleMic,
        child: Icon(listening ? Icons.stop : Icons.mic),
      ),
    );
  }
}