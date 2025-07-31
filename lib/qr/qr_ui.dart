import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class TextForm extends StatelessWidget {
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  const TextForm(this.textController, this.onChanged, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return TextFormField(
      controller: textController,
      decoration: const InputDecoration(
        labelText: 'TEXT',
        border: OutlineInputBorder(),
      ),
      maxLines: null,
      onChanged: onChanged,
      validator: (s) =>
      (s == null || s.trim().isEmpty)
          ? 'Please enter some text'
          : null,
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
    return TextFormField(
      controller: urlController,
      decoration: const InputDecoration(
        labelText: 'LINK',
        hintText: 'https://example.com',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.url,
      onChanged: onChanged,
      validator: (s) {
        if (s == null || s.trim().isEmpty) {
          return 'Please enter a URL';
        }
        final raw = s.trim();
        final uri = Uri.tryParse(raw);
        if (uri == null || uri.host.isEmpty) {
          return 'Enter a valid URL';
        }
        return null;
      },

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
        TextFormField(
          controller: ctrls['name']!,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
          validator: (s) =>
          (s == null || s.trim().isEmpty)
              ? 'Please enter some text'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: ctrls['email']!,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
          validator: (s) {
            if (s == null || s.trim().isEmpty) return 'Required';
            return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)
                ? null
                : 'Invalid email';
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: ctrls['phone']!,
          decoration: InputDecoration(
            labelText: 'Phone',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
          validator: (s) =>
          (s == null || !RegExp(r'^\+?\d{7,15}$').hasMatch(s))
              ? 'Invalid phone'
              : null,

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
        TextFormField(
          controller: ssidCtrl,
          decoration: const InputDecoration(labelText: 'Network Name', border: OutlineInputBorder()),
          onChanged: (_) => onChanged(''),
          validator: (s) =>
          (s == null || s.trim().isEmpty)
              ? 'Please enter some text'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          obscureText: true,
          onChanged: (_) => onChanged(''),
          validator: (s) =>
          (s == null || s.trim().isEmpty)
              ? 'Please enter some text'
              : null,
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
    return TextFormField(
      controller: phoneCtrl,
      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
      keyboardType: TextInputType.phone,
      onChanged: (_) => onChanged(''),
      validator: (s) =>
      (s == null || !RegExp(r'^\+?\d{7,15}$').hasMatch(s))
          ? 'Invalid phone'
          : null,

    );
  }
}

