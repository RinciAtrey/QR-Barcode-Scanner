import 'package:flutter/material.dart';


class TextForm extends StatelessWidget {
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  const TextForm(this.textController, this.onChanged, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return TextField(
      controller: textController,
     // style: TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: 'TEXT',
        border: OutlineInputBorder(),
      ),
      maxLines: null,
      onChanged: onChanged,
    );
  }
}


class UrlForm extends StatelessWidget {
  final TextEditingController urlController;
  final ValueChanged<String> onChanged;
  const UrlForm(this.urlController, this.onChanged, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return TextField(
      controller: urlController,
      decoration: const InputDecoration(
        labelText: 'LINK',
        hintText: 'https://example.com',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.url,
      onChanged: onChanged,
    );
  }
}

class ContactForm extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  final ValueChanged<String> onChanged;
  const ContactForm(this.ctrls, this.onChanged, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        TextField(
          controller: ctrls['name']!,
          decoration: const InputDecoration(
            labelText: 'FIRST NAME',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrls['email']!,
          decoration: const InputDecoration(
            labelText: 'EMAIL',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrls['phone']!,
          decoration: InputDecoration(
            labelText: 'WORK PHONE',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
              },
            ),
          ),
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class WifiForm extends StatelessWidget {
  final TextEditingController ssidCtrl;
  final TextEditingController passCtrl;
  final ValueChanged<String> onChanged;
  const WifiForm(this.ssidCtrl, this.passCtrl, this.onChanged, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        TextField(
          controller: ssidCtrl,
          decoration: const InputDecoration(labelText: 'Network Name', border: OutlineInputBorder()),
          onChanged: (_) => onChanged(''), // trigger regeneration
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          obscureText: true,
          onChanged: (_) => onChanged(''),
        ),
      ],
    );
  }
}


class CallForm extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final ValueChanged<String> onChanged;
  const CallForm(this.phoneCtrl, this.onChanged, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return TextField(
      controller: phoneCtrl,
      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
      keyboardType: TextInputType.phone,
      onChanged: (_) => onChanged(''),
    );
  }
}

